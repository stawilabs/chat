package business

import "testing"

func TestRoleListContains(t *testing.T) {
	cases := []struct {
		name     string
		field    string
		target   string
		expected bool
	}{
		{"single match", "owner", "owner", true},
		{"single no match", "member", "owner", false},
		{"csv first", "owner,admin", "owner", true},
		{"csv last", "admin,owner", "owner", true},
		{"csv middle", "admin,owner,member", "owner", true},
		{"csv with spaces", "admin, owner", "owner", true},
		{"substring is not a match", "co-owner", "owner", false},
		{"empty field", "", "owner", false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := roleListContains(tc.field, tc.target); got != tc.expected {
				t.Fatalf("roleListContains(%q,%q)=%v want %v", tc.field, tc.target, got, tc.expected)
			}
		})
	}
}

func TestUniqueStrings(t *testing.T) {
	got := uniqueStrings([]string{"a", "b", "a", "c", "b"})
	if len(got) != 3 {
		t.Fatalf("expected 3 unique, got %d (%v)", len(got), got)
	}
	seen := map[string]int{}
	for _, v := range got {
		seen[v]++
	}
	for _, v := range []string{"a", "b", "c"} {
		if seen[v] != 1 {
			t.Fatalf("expected %q exactly once, got %d", v, seen[v])
		}
	}
}
