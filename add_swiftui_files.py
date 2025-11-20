#!/usr/bin/env python3
"""
Script to add SwiftUI files to the Xcode project
"""
import re
import uuid

def generate_xcode_uuid():
    """Generate a UUID in Xcode format (24 hex characters)"""
    return uuid.uuid4().hex[:24].upper()

def add_swiftui_files_to_project(project_path):
    """Add SwiftUI files to the Xcode project"""

    with open(project_path, 'r') as f:
        content = f.read()

    # SwiftUI files to add
    swiftui_files = [
        'GameView.swift',
        'GameStatusView.swift',
        'BoardGridView.swift',
        'GameControlsView.swift'
    ]

    # Generate UUIDs for each file
    file_refs = {}
    build_files = {}

    for filename in swiftui_files:
        file_refs[filename] = generate_xcode_uuid()
        build_files[filename] = generate_xcode_uuid()

    group_uuid = generate_xcode_uuid()

    # 1. Add PBXBuildFile entries
    build_file_section = "/* Begin PBXBuildFile section */"
    build_file_entries = "\n"
    for filename in swiftui_files:
        build_file_entries += f"\t\t{build_files[filename]} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[filename]} /* {filename} */; }};\n"

    content = content.replace(
        "/* End PBXBuildFile section */",
        build_file_entries + "/* End PBXBuildFile section */"
    )

    # 2. Add PBXFileReference entries
    file_ref_entries = "\n"
    for filename in swiftui_files:
        file_ref_entries += f"\t\t{file_refs[filename]} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"

    content = content.replace(
        "/* End PBXFileReference section */",
        file_ref_entries + "/* End PBXFileReference section */"
    )

    # 3. Add SwiftUI group
    swiftui_group = f"""		{group_uuid} /* SwiftUI */ = {{
			isa = PBXGroup;
			children = (
"""
    for filename in swiftui_files:
        swiftui_group += f"\t\t\t\t{file_refs[filename]} /* {filename} */,\n"

    swiftui_group += """			);
			path = SwiftUI;
			sourceTree = "<group>";
		};
"""

    # Find the Reversi group and add SwiftUI group reference
    reversi_group_pattern = r'(D642BDB223A9FE4500396732 /\* Reversi \*/ = \{[\s\S]*?children = \([\s\S]*?)(D636B3A423D432D3007F370E /\* Models \*/,)'

    def add_swiftui_to_group(match):
        return match.group(1) + f"\t\t\t\t{group_uuid} /* SwiftUI */,\n\t\t\t\t" + match.group(2)

    content = re.sub(reversi_group_pattern, add_swiftui_to_group, content)

    # Add the SwiftUI group definition before the end of PBXGroup section
    content = content.replace(
        "/* End PBXGroup section */",
        swiftui_group + "\t/* End PBXGroup section */"
    )

    # 4. Add to PBXSourcesBuildPhase
    sources_phase_pattern = r'(D642BDAE23A9FE4500396732 /\* Sources \*/ = \{[\s\S]*?files = \([\s\S]*?)([\s\S]*?\);\s+runOnlyForDeploymentPostprocessing = 0;)'

    sources_entries = ""
    for filename in swiftui_files:
        sources_entries += f"\t\t\t\t{build_files[filename]} /* {filename} in Sources */,\n"

    def add_to_sources(match):
        return match.group(1) + sources_entries + match.group(2)

    content = re.sub(sources_phase_pattern, add_to_sources, content)

    # Write back
    with open(project_path, 'w') as f:
        f.write(content)

    print("Successfully added SwiftUI files to Xcode project!")
    print("\nGenerated UUIDs:")
    for filename in swiftui_files:
        print(f"  {filename}: FileRef={file_refs[filename]}, BuildFile={build_files[filename]}")
    print(f"  SwiftUI Group: {group_uuid}")

if __name__ == '__main__':
    project_path = '/home/user/reversi-ios/Reversi.xcodeproj/project.pbxproj'
    add_swiftui_files_to_project(project_path)
