# OverClocked

OverClocked is a comprehensive system monitoring and reporting tool that collects, processes, and visualizes system metrics. This project includes customizable scripts, reports, and templates tailored for different operating systems.

## Features

Data Collection: Scripts to gather system metrics (CPU, memory, GPU, etc.) for Linux, macOS, and Windows.

Visualization: Tools to generate live graphs and detailed HTML reports.

Automation: Bash scripts for automated metric collection and report generation.

Database Integration: Stores metrics in a SQLite database for persistent monitoring.


## Directory Structure

scripts/: Contains core scripts for data collection, graph generation, and reporting.

templates/: HTML templates for system reports.

static/: Includes CSS for report styling.

reports/: Pre-generated system reports.


## Requirements

Python 3.13+

SQLite

Bash (for automation scripts)


## Setup

1. Clone the repository:

git clone <repository-url>
cd OverClocked


2. Install dependencies:

pip install -r requirements.txt


3. Set up the environment:

source .env/bin/activate


4. Configure scripts in scripts/ for your operating system.



## Usage

### Collect Metrics

Run the appropriate script based on your OS:

#### Linux:

bash scripts/collect_linux_metrics.sh

#### macOS:

bash scripts/collect_macos_metrics.sh


### Generate Reports

python3 scripts/report_metrics.py

Visualize Data

Run the live graphing tool:

python3 scripts/live_graph.py

## Contributing

Feel free to submit issues and pull requests to improve the project.

## License

This project is licensed under the MIT License.
