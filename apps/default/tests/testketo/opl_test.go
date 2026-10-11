package testketo_test

import (
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"slices"
	"sort"
	"strings"
	"testing"

	chatpb "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/antinvestor/common/v2/permissions"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/tests/testketo"
)

func serviceChatOPL(t *testing.T) string {
	t.Helper()
	_, thisFile, _, _ := runtime.Caller(0)
	content, err := os.ReadFile(filepath.Join(filepath.Dir(thisFile), "..", "..", "..", "..",
		"opl", "chat", "service_chat.opl.ts"))
	require.NoError(t, err)
	return string(content)
}

// TestServiceChatOPLMatchesManifest holds the published service_chat
// namespace to ChatService's permission manifest, the one setup registers
// with tenancy: every permission has its granted_ relation and a permit, and
// each permit admits exactly the roles the manifest binds it to. Tenancy
// writes role and granted_ tuples from the manifest; a permit Keto does not
// define, or one admitting other roles, would deny or over-grant them.
func TestServiceChatOPLMatchesManifest(t *testing.T) {
	manifest := permissions.BuildManifest(chatpb.File_chat_v1_chat_proto.Services().ByName("ChatService"))
	require.Equal(t, "service_chat", manifest.Namespace)

	opl := serviceChatOPL(t)
	permitRe := regexp.MustCompile(
		`(?m)^    (\w+): \(ctx: Context\): boolean =>\n((?:      this\.related\.\w+\.includes\(ctx\.subject\)(?: \|\||,)?\n)+)`,
	)
	termRe := regexp.MustCompile(`this\.related\.(\w+)\.includes`)
	permits := map[string][]string{}
	for _, m := range permitRe.FindAllStringSubmatch(opl, -1) {
		for _, term := range termRe.FindAllStringSubmatch(m[2], -1) {
			permits[m[1]] = append(permits[m[1]], term[1])
		}
	}

	defined := make([]string, 0, len(permits))
	for permission := range permits {
		defined = append(defined, permission)
	}
	want := slices.Clone(manifest.Permissions)
	sort.Strings(defined)
	sort.Strings(want)
	require.Equal(t, want, defined, "service_chat permits")

	for _, permission := range manifest.Permissions {
		require.Contains(t, opl, "    granted_"+permission+": (profile_user | service_chat)[]\n", permission)

		var roles []string
		for role, bound := range manifest.RoleBindings {
			if slices.Contains(bound, permission) {
				roles = append(roles, role)
			}
		}
		sort.Strings(roles)
		require.Equal(t, append(roles, "granted_"+permission), permits[permission], permission)
	}
}

// TestEveryPersonMayStartARoom: tenancy gives each person of a partition the
// member role and nothing more, so member must carry room_create and
// subscription_manage or no one could start a group or add people to it.
// What a person may do inside a given room is chat_room's to decide.
func TestEveryPersonMayStartARoom(t *testing.T) {
	manifest := permissions.BuildManifest(chatpb.File_chat_v1_chat_proto.Services().ByName("ChatService"))
	member := manifest.RoleBindings["member"]
	require.Contains(t, member, "room_create")
	require.Contains(t, member, "subscription_manage")
	require.NotContains(t, member, "room_update")
	require.NotContains(t, member, "room_delete")
}

// TestNamespacesOPLDeclaresEachClassOnce checks the merged document the test
// Keto loads: one import and every chat namespace exactly once.
func TestNamespacesOPLDeclaresEachClassOnce(t *testing.T) {
	opl, err := testketo.NamespacesOPL()
	require.NoError(t, err)
	require.Equal(t, 1, strings.Count(opl, "import "))
	for _, class := range []string{
		"profile_user", "tenancy_access", "service_chat",
		"chat_profile", "chat_subscription", "chat_room", "chat_message",
	} {
		require.Equal(t, 1, strings.Count(opl, "class "+class+" implements Namespace"), class)
	}
}
