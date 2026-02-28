package testketo

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/pitabwire/frame/frametests/definition"
	"github.com/pitabwire/frame/frametests/deps/testpostgres"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

const (
	// ImageName is the Ory Keto image used for test containers.
	ImageName = "oryd/keto:latest"

	ketoConfiguration = `
version: v0.14.0

dsn: memory

serve:
  read:
    host: 0.0.0.0
    port: 4466
    max_read_depth: 10
  write:
    host: 0.0.0.0
    port: 4467

log:
  level: debug
  format: text

namespaces:
  location: file:///home/ory/namespaces/chat.ts

`

	// oplNamespaces is the OPL namespace definition for the chat service.
	// It is embedded here so that the test container can mount it without
	// depending on the file system path of the source tree.
	// NOTE: Class names are prefixed with "chat_" to avoid collisions with
	// other services sharing the same Keto instance. Must match Go constants
	// (e.g., NamespaceRoom = "chat_room"). Keto uses exact class names.
	// Direct-grant relations are prefixed with "granted_" to avoid name
	// conflicts with permit functions. Keto skips permit evaluation when a
	// relation shares the same name as a permit function.
	oplNamespaces = `import { Namespace, Context } from "@ory/keto-namespace-types"

class profile_user implements Namespace {}

class tenancy_access implements Namespace {
  related: {
    granted_member: profile_user[]
    granted_service: profile_user[]
  }
}

class chat_profile implements Namespace {
  related: {
    self: chat_profile[]
  }
}

class chat_subscription implements Namespace {}

class chat_room implements Namespace {
  related: {
    granted_owner: (chat_profile | chat_subscription)[]
    granted_admin: (chat_profile | chat_subscription)[]
    granted_member: (chat_profile | chat_subscription)[]
    granted_viewer: (chat_profile | chat_subscription)[]
  }

  permits = {
    view: (ctx: Context): boolean =>
      this.related.granted_viewer.includes(ctx.subject) ||
      this.related.granted_member.includes(ctx.subject) ||
      this.related.granted_admin.includes(ctx.subject) ||
      this.related.granted_owner.includes(ctx.subject),

    message_send: (ctx: Context): boolean =>
      this.related.granted_member.includes(ctx.subject) ||
      this.related.granted_admin.includes(ctx.subject) ||
      this.related.granted_owner.includes(ctx.subject),

    message_delete_any: (ctx: Context): boolean =>
      this.related.granted_admin.includes(ctx.subject) ||
      this.related.granted_owner.includes(ctx.subject),

    update: (ctx: Context): boolean =>
      this.related.granted_admin.includes(ctx.subject) ||
      this.related.granted_owner.includes(ctx.subject),

    delete: (ctx: Context): boolean =>
      this.related.granted_owner.includes(ctx.subject),

    members_manage: (ctx: Context): boolean =>
      this.related.granted_admin.includes(ctx.subject) ||
      this.related.granted_owner.includes(ctx.subject),

    roles_manage: (ctx: Context): boolean =>
      this.related.granted_owner.includes(ctx.subject),
  }
}

class chat_message implements Namespace {
  related: {
    granted_sender: chat_profile[]
    room: chat_room[]
  }

  permits = {
    view: (ctx: Context): boolean =>
      this.related.room.traverse((r) => r.permits.view(ctx)),

    delete: (ctx: Context): boolean =>
      this.related.granted_sender.includes(ctx.subject) ||
      this.related.room.traverse((r) => r.permits.message_delete_any(ctx)),

    edit: (ctx: Context): boolean =>
      this.related.granted_sender.includes(ctx.subject),

    react: (ctx: Context): boolean =>
      this.related.room.traverse((r) => r.permits.message_send(ctx)),
  }
}
`
)

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
				ContainerFilePath: "/home/ory/keto.yml",
				FileMode:          definition.ContainerFileMode,
			},
			{
				Reader:            strings.NewReader(oplNamespaces),
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

	if err = d.migrateContainer(ctx, ntwk, databaseURL); err != nil {
		return err
	}

	containerRequest := testcontainers.ContainerRequest{
		Image: d.Name(),
		Cmd:   []string{"serve", "--config", "/home/ory/keto.yml"},
		Env: d.Opts().Env(map[string]string{
			"LOG_LEVEL":                 "debug",
			"LOG_LEAK_SENSITIVE_VALUES": "true",
			"DSN":                       databaseURL,
		}),
		Files: []testcontainers.ContainerFile{
			{
				Reader:            strings.NewReader(ketoConfiguration),
				ContainerFilePath: "/home/ory/keto.yml",
				FileMode:          definition.ContainerFileMode,
			},
			{
				Reader:            strings.NewReader(oplNamespaces),
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
