#!/usr/bin/env python3
"""
JSON Schema Validation Test Script

This script tests whether a specified JSON file conforms
to a specified JSON schema.
"""

import argparse
import json
import sys
from pathlib import Path
import jsonschema


def validate_json_schema(json_file: Path, schema_file: Path) -> bool:
    """
    Validate JSON file against schema

    Args:
        json_file: Path to JSON file to be validated
        schema_file: Path to JSON schema file

    Returns:
        True if validation succeeds, False if it fails
    """
    try:
        # Load schema file
        with open(schema_file, "r", encoding="utf-8") as f:
            schema = json.load(f)

        # Load JSON file
        with open(json_file, "r", encoding="utf-8") as f:
            data = json.load(f)

        # Execute validation
        jsonschema.validate(data, schema)

        return True

    except FileNotFoundError as e:
        print(f"ERROR: File not found: {e.filename}", file=sys.stderr)
        return False

    except json.JSONDecodeError as e:
        print(
            f"ERROR: JSON parse error: {e.msg} at line {e.lineno}, column {e.colno}",
            file=sys.stderr,
        )
        return False

    except jsonschema.exceptions.ValidationError as e:
        print(f"INVALID: {e.message}", file=sys.stderr)
        if e.json_path:
            print(f"  Location: {e.json_path}", file=sys.stderr)
        return False

    except jsonschema.exceptions.SchemaError as e:
        print(f"ERROR: Schema error: {e.message}", file=sys.stderr)
        return False

    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return False


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description="Test if JSON file conforms to JSON schema",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s schema.json data.json
        """,
    )

    parser.add_argument("schema", type=str, help="JSON schema file name")

    parser.add_argument("json_file", type=str, help="JSON file to be validated")

    args = parser.parse_args()

    # Resolve JSON file path
    json_file = Path(args.json_file).resolve()
    if not json_file.exists():
        print(f"ERROR: JSON file not found: {json_file}", file=sys.stderr)
        sys.exit(1)

    # Schema file can be absolute path or relative to JSON file directory
    if Path(args.schema).is_absolute():
        schema_file = Path(args.schema)
    else:
        schema_file = json_file.parent / args.schema

    if not schema_file.exists():
        print(f"ERROR: Schema file not found: {schema_file}", file=sys.stderr)
        sys.exit(1)

    # Execute validation
    is_valid = validate_json_schema(json_file, schema_file)

    # Exit code
    sys.exit(0 if is_valid else 1)


if __name__ == "__main__":
    main()
