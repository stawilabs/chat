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

func TestIsValidRoomID(t *testing.T) {
	if !IsValidRoomID(util.IDString()) {
		t.Fatal("a generated xid must be valid")
	}
	for _, bad := range []string{"", "not-an-xid", "zzzzzzzzzzzzzzzzzzzz", "room-1", "../etc/passwd"} {
		if IsValidRoomID(bad) {
			t.Fatalf("expected %q to be rejected", bad)
		}
	}
}
