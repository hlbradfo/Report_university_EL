# Create university-level report
Create generic summary report for university data for internal use.

## Description

Generates report with the following structure
- Destinations
  - College
    - Overall means
    - Means and gaps by demographic
    - Demographics for all outcomes
    - Multi-way interactions
    - GOVA maps
  - Discipline
    - Overall means
    - Means and gaps by demographic
    - Demographics for all outcomes
    - GOVA maps
- Self-report participation
  - College
    - Overall means
    - Means and gaps by demographic
    - Demographics for all outcomes
    - Multi-way interactions
    - GOVA maps
  - Discipline
    - Overall means
    - Means and gaps by demographic
    - Demographics for all outcomes
    - GOVA maps
- Enrollment participation
  - College
    - Overall means
    - Means and gaps by demographic
    - Demographics for all outcomes
    - Multi-way interactions
    - GOVA maps
  - Discipline
    - Overall means
    - Means and gaps by demographic
    - Demographics for all outcomes
    - GOVA maps
    
   
## File descriptions

### Scripts
| File Name | Description |
| --------- | ----------- |
| Full_summary.sas | Create university-level report |

### Input data
| SAS dataset name | Description |
| ---------------- | ----------- |
| enrollMeans | Overall means for enrollments |
| enrollMeansInt1 | 1-way interactions for enrollments |
| enrollMeansInt2 | Multi-way interactions for enrollments |
| fdsMeans | Overall means for First Destination Survey |
| fdsMeansInt1 | 1-way interactions for First Destination Survey |
| fdsMeansInt2 | Multi-way interactions for First Destination Survey |

### Output files
Report is output as participation.rft in One Drive data files. 

## Use

Prerequisite: All data editing and summary scripts complete and up-to-date.

Run Full_summary.sas to create the report. Adjust the parameters at the top of the report to accomodate changes in years, demographics, or questions.

## Author

Heather Bradford  
Project Management Specialist  
Center for Excellence in Teaching and Learning  
Virginia Tech  
