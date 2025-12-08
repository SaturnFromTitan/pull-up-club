import "package:flutter_test/flutter_test.dart";
import "package:pull_up_club/main.dart";

void main() {
  group("checkIfUpdateRequired", () {
    test("returns true when current version is older", () {
      expect(
        checkIfUpdateRequired(currentVersion: "0.9.9", minAppVersion: "1.0.0"),
        isTrue,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.0", minAppVersion: "1.0.1"),
        isTrue,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.2", minAppVersion: "1.0.10"),
        isTrue,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.0", minAppVersion: "1.1.0"),
        isTrue,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.0", minAppVersion: "2.0.0"),
        isTrue,
      );
    });

    test("returns false when versions are equal", () {
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.0", minAppVersion: "1.0.0"),
        isFalse,
      );
    });

    test("returns false when current version is newer", () {
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.0", minAppVersion: "0.9.9"),
        isFalse,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.1", minAppVersion: "1.0.0"),
        isFalse,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.10", minAppVersion: "1.0.2"),
        isFalse,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "1.1.0", minAppVersion: "1.0.0"),
        isFalse,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "2.0.0", minAppVersion: "1.0.0"),
        isFalse,
      );
    });

    test("handles pre-release versions", () {
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.0-alpha", minAppVersion: "1.0.0"),
        isTrue,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.0", minAppVersion: "1.0.0-beta"),
        isFalse,
      );
    });

    test("returns false on invalid version format (fail open)", () {
      expect(
        checkIfUpdateRequired(currentVersion: "invalid", minAppVersion: "1.0.0"),
        isFalse,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.0", minAppVersion: "invalid"),
        isFalse,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "not.a.version", minAppVersion: "1.0.0"),
        isFalse,
      );
      expect(
        checkIfUpdateRequired(currentVersion: "1.0.0", minAppVersion: "also.invalid"),
        isFalse,
      );
    });
  });
}
