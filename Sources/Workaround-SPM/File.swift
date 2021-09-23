// Xcode 12 has an issue where the first build after
// cleaning fails if there is a dependency that vends
// a binary .xcframework (Sodium, in this case.) We
// are working around this on CI by first building this
// "_WorkaroundSPM" target that _only_ builds that one
// dependency. We ignore any failures when building this
// target. Then we go on to build the actual product, which
// builds correctly.
//
// The "_WorkaroundSPM" target needs something to compile,
// though, which is why this file exists.
import Sodium
