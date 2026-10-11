package testketo

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strings"

	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/frame/v2/frametests/deps/testpostgres"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

const (
	// ImageName is the Ory Keto image used for test containers.
	ImageName = "oryd/keto:latest"

	ketoConfigPath = "/home/ory/keto.yml"

	ketoConfiguration = `
limit:
  max_read_depth: 10

serve:
  read:
    host: 0.0.0.0
    port: 4466
  write:
    host: 0.0.0.0
    port: 4467

log:
  level: debug
  format: text

namespaces:
  location: file:///home/ory/namespaces/chat.ts

`
)

// oplHeader is the single import every merged OPL document starts with.
const oplHeader = `import { Namespace, Context } from "@ory/keto-namespace-types"` + "\n"

var oplClass = regexp.MustCompile(`(?m)^class\s+(\w+)\s+implements\s+Namespace\s*\{`)

// oplDir is the repository's opl/ directory: the namespace definitions chat
// publishes to the platform's Keto (opl-push in the release workflow).
func oplDir() string {
	_, thisFile, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(thisFile), "..", "..", "..", "..", "opl")
}

// NamespacesOPL merges every opl/**/*.opl.ts file into one Keto namespace
// document, as opl-push merges them into the platform's namespaces.ts: one
// import header, and each class once (the shared base classes profile_user
// and tenancy_access are declared by more than one fragment). The test Keto
// loads exactly what chat publishes, so a test cannot pass against an OPL
// production does not run.
func NamespacesOPL() (string, error) {
	var files []string
	err := filepath.WalkDir(oplDir(), func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() && strings.HasSuffix(path, ".opl.ts") {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		return "", fmt.Errorf("read opl directory: %w", err)
	}
	sort.Strings(files)

	var b strings.Builder
	b.WriteString(oplHeader)
	seen := map[string]bool{}
	for _, file := range files {
		content, readErr := os.ReadFile(file)
		if readErr != nil {
			return "", readErr
		}
		text := string(content)
		matches := oplClass.FindAllStringSubmatchIndex(text, -1)
		for i, m := range matches {
			name := text[m[2]:m[3]]
			end := len(text)
			if i+1 < len(matches) {
				end = matches[i+1][0]
			}
			if seen[name] {
				continue
			}
			seen[name] = true
			b.WriteString("\n")
			b.WriteString(strings.TrimRight(text[m[0]:end], " \n"))
			b.WriteString("\n")
		}
	}
	if len(seen) == 0 {
		return "", errors.New("no OPL classes found under " + oplDir())
	}
	return b.String(), nil
}

type dependancy struct {
	*definition.DefaultImpl
}

// NewWithOpts creates a new Keto test resource with OPL namespace support.
// It requires a PostgreSQL dependency for Keto's persistent storage.
func NewWithOpts(
	containerOpts ...definition.ContainerOption,
) definition.TestResource {
	opts := definition.ContainerOpts{
		ImageName:      ImageName,
		Ports:          []string{"4467/tcp", "4466/tcp"},
		NetworkAliases: []string{"keto", "auth-keto"},
	}
	opts.Setup(containerOpts...)

	return &dependancy{
		DefaultImpl: definition.NewDefaultImpl(opts, "http"),
	}
}

func (d *dependancy) migrateContainer(
	ctx context.Context,
	ntwk *testcontainers.DockerNetwork,
	databaseURL string,
	opl string,
) error {
	containerRequest := testcontainers.ContainerRequest{
		Image: d.Name(),
		Cmd:   []string{"migrate", "up", "--yes"},
		Env: map[string]string{
			"LOG_LEVEL": "debug",
			"DSN":       databaseURL,
		},
		Files: []testcontainers.ContainerFile{
			{
				Reader:            strings.NewReader(ketoConfiguration),
				ContainerFilePath: ketoConfigPath,
				FileMode:          definition.ContainerFileMode,
			},
			{
				Reader:            strings.NewReader(opl),
				ContainerFilePath: "/home/ory/namespaces/chat.ts",
				FileMode:          definition.ContainerFileMode,
			},
		},
		WaitingFor: wait.ForExit(),
	}

	d.Configure(ctx, ntwk, &containerRequest)

	ketoContainer, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: containerRequest,
		Started:          true,
	})
	if err != nil {
		return fmt.Errorf("failed to start keto migration container: %w", err)
	}

	if err = ketoContainer.Terminate(ctx); err != nil {
		return fmt.Errorf("failed to terminate keto migration container: %w", err)
	}
	return nil
}

func (d *dependancy) Setup(ctx context.Context, ntwk *testcontainers.DockerNetwork) error {
	if len(d.Opts().Dependencies) == 0 || !d.Opts().Dependencies[0].GetDS(ctx).IsDB() {
		return errors.New("no database dependency was supplied")
	}

	ketoDB, _, err := testpostgres.CreateDatabase(ctx, d.Opts().Dependencies[0].GetInternalDS(ctx), "keto")
	if err != nil {
		return fmt.Errorf("failed to create keto database: %w", err)
	}

	databaseURL := ketoDB.String()

	opl, err := NamespacesOPL()
	if err != nil {
		return err
	}

	if err = d.migrateContainer(ctx, ntwk, databaseURL, opl); err != nil {
		return err
	}

	containerRequest := testcontainers.ContainerRequest{
		Image: d.Name(),
		Cmd:   []string{"serve", "--config", ketoConfigPath},
		Env: d.Opts().Env(map[string]string{
			"LOG_LEVEL":                 "debug",
			"LOG_LEAK_SENSITIVE_VALUES": "true",
			"DSN":                       databaseURL,
		}),
		Files: []testcontainers.ContainerFile{
			{
				Reader:            strings.NewReader(ketoConfiguration),
				ContainerFilePath: ketoConfigPath,
				FileMode:          definition.ContainerFileMode,
			},
			{
				Reader:            strings.NewReader(opl),
				ContainerFilePath: "/home/ory/namespaces/chat.ts",
				FileMode:          definition.ContainerFileMode,
			},
		},
		WaitingFor: wait.ForHTTP("/health/ready").WithPort(d.DefaultPort),
	}

	d.Configure(ctx, ntwk, &containerRequest)

	ketoContainer, err := testcontainers.GenericContainer(ctx,
		testcontainers.GenericContainerRequest{
			ContainerRequest: containerRequest,
			Started:          true,
		})
	if err != nil {
		return fmt.Errorf("failed to start keto serve container: %w", err)
	}

	d.SetContainer(ketoContainer)
	return nil
}
