from hypothesis import Phase, settings, Verbosity

settings.register_profile("no-shrink", settings(verbosity=Verbosity.verbose, phases=list(Phase)[:4]))
