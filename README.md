# Fz: Multithreaded Fuzzy File Finder

## Overview

Fz is a minimal, multithreaded fuzzy file finder written entirely in D programming language. It provides a fast and efficient way to search for files within a directory using fuzzy matching, all within a terminal-based user interface.

## Features

- **Fuzzy Matching:** Employs a powerful fuzzy matching algorithm for accurate and flexible file searches.

- **Multithreaded Execution:** Leverages D's native support for multithreading to enhance search speed and responsiveness.

- **Text User Interface (TUI):** Initiates a TUI for an interactive and intuitive file search experience.

## Usage

```bash
./fz
```

After running the above command, a TUI will be launched, guiding you through the process of searching for files interactively.

## Dependencies

- D programming language compiler and runtime.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/bhaskar0120/fz.git
   ```

2. Build the executable:

   ```bash
   cd fz
   dmd fuzzy.d
   ```

3. Run the TUI:

   ```bash
   ./fz
   ```

## License

This project is licensed under the [MIT License](LICENSE).

---
