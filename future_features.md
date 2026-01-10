# Future Features

## Brother Scanner Support (DCP-L2540DW)

**Goal**: Enable "Scan to File" functionality for Brother DCP-L2540DW.

**Current Status**:
- Postponed to avoid potential stability issues on initial boot.
- Printing support (CUPS) is installed, but scanner drivers are not.

**Research Findings**:
- **Drivers Required**:
    - `brscan4`: SANE driver for the scanner.
    - `brscan-skey`: Tool to enable the physical "Scan" button on the device to send files to the computer.
- **Source Files**:
    - `brscan4`: `https://download.brother.com/welcome/dlf105203/brscan4-0.4.11-1.x86_64.rpm`
    - `brscan-skey`: Directly available via Brother's installer tool, or discoverable via AUR pkgbuilds. Typically found at:
        - `http://download.brother.com/welcome/dlf006650/brscan-skey-0.3.4-0.x86_64.rpm` (Need to verify if this direct link works and is stable).

**Implementation Strategy for Atomic Fedora**:
1.  **RPM Installation**:
    - Use the `rpm-ostree` module in the recipe to install these RPMs directly from their URLs.
    - Example:
      ```yaml
      - type: rpm-ostree
        install:
          - https://download.brother.com/welcome/dlf105203/brscan4-0.4.11-1.x86_64.rpm
          - http://download.brother.com/welcome/dlf006650/brscan-skey-0.3.4-0.x86_64.rpm
      ```
2.  **Configuration**:
    - `brscan-skey` might need a systemd service enabled or a user-session script to auto-start.
    - Network configuration: Use `brsaneconfig4` (installed by the package) to set up the scanner IP if it's network-attached. This is a post-install step that might need a "firstboot" script or manual user intervention.
