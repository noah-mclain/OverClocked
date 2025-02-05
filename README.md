

# OverClocked

**OverClocked** is a comprehensive system monitoring and reporting tool designed to collect, process, and visualize system metrics. The project includes customizable scripts, reports, and templates tailored for different operating systems.

---

## **Features**
- **Data Collection**: Scripts to gather system metrics (CPU, memory, GPU, etc.) for Linux, macOS, and Windows.  
- **Visualization**: Tools to generate live graphs and detailed HTML reports.  
- **Automation**: Bash scripts for automated metric collection and report generation.  
- **Database Integration**: Stores metrics in a SQLite database for persistent monitoring.  

---

## **Directory Structure**

OverClocked/
├── scripts/    # Core scripts for data collection, graph generation, and reporting.
├── templates/  # HTML templates for system reports.
├── static/     # CSS files for report styling.
└── reports/    # Pre-generated system reports.

---

## **Requirements**
- **Python**: Version 3.13+  
- **SQLite**  
- **Bash**: For automation scripts  

---

## **Setup**

1. **Clone the repository:**
   ```bash
   git clone https://github.com/username/OverClocked.git
   cd OverClocked

2. **Install Dependencies:**
			```bash
			pip install -r requirements.txt

3.	**Set up the environment:**
			```bash
			source .env/bin/activate

	4.	**Configure the scripts in the scripts/ directory for your operating system.**

## **Usage**

**Collect Metrics**

Run the appropriate script based on your operating system:
	•	Linux:
			```bash
			scripts/collect_linux_metrics.sh

	•	macOS:
			```bash
		 scripts/collect_macos_metrics.sh



## **Generate Reports**

**Generate detailed system reports:**

			```bash
			python3 scripts/report_metrics.py

## **Visualize Data**

Run the live graphing tool to visualize metrics in real-time:

			```bash
			python3 scripts/live_graph.py

## **Contributing**

Contributions are welcome! Feel free to submit issues and pull requests to improve this project.

## **License**

This project is licensed under the MIT License. See the LICENSE file for more details.

