from hypothesis import Phase, settings, Verbosity

settings.register_profile("debug", settings(verbosity=Verbosity.verbose, phases=list(Phase)[:4]))
