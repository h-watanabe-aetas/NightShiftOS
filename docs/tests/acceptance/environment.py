"""behave shared hooks for acceptance tests."""


def before_all(context):
    # Common metadata for step implementations.
    context.project_name = "NightShiftOS"
