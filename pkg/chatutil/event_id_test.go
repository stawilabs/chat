package chatutil

import (
	"testing"

	"github.com/pitabwire/util"
)

func TestIsValidEventID(t *testing.T) {
	if !IsValidEventID(util.IDString()) {
		t.Fatal("a generated xid must be valid")
	}
	for _, bad := range []string{"", "not-an-xid", "zzzzzzzzzzzzzzzzzzzz", "!", "../etc/passwd"} {
		if IsValidEventID(bad) {
			t.Fatalf("expected %q to be rejected", bad)
		}
	}
}
