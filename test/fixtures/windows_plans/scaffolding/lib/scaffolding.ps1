[Diagnostics.CodeAnalysis.SuppressMessage("PSUseApprovedVerbs", '', Scope="function")]
param()
function Load-Scaffolding {
    $pkg_deps += @("habitat-testing/dummy")
    $pkg_build_deps += @("habitat-testing/dummy-hab-user")
}
