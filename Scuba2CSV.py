import os
import re
import sys
import csv

def ACQ():
    compos = os.getenv('COMPUTERNAME')
    dir = os.getcwd()
    acq_path = os.path.join(dir, compos, "Scuba","ScubaCSV.csv")
    return acq_path

def parse_file(file_content):
    acq_file = ACQ()
    test_pattern = "'test': '(.*)',"
    severity_pattern = "'severity': '(.*)',"
    regulations_pattern = r"'regulations': \[(.*?)\],"
    result_pattern = "'result': '(.*)',"
    category_pattern = "'category': '(.*)',"
    description_pattern = "'description': '(.*)',"
    remediation_pattern = "'remediation': '(.*)',"
    cveLink_pattern = "'cveLink': '(.*)',"
    details_pattern = "'details': '(.*)',"
    data_pattern = r"'data': \[(.*)\],"
    score_pattern = "'score': '(.*)',"
    test_result = re.findall(test_pattern, file_content)
    severity_result = re.findall(severity_pattern, file_content)
    regulations_result = re.findall(regulations_pattern, file_content)
    result_result = re.findall(result_pattern, file_content)
    category_result = re.findall(category_pattern, file_content)
    description_result = re.findall(description_pattern, file_content)
    remediation_result = re.findall(remediation_pattern, file_content)
    cveLink_result = re.findall(cveLink_pattern, file_content)
    details_result = re.findall(details_pattern, file_content)
    data_result = re.findall(data_pattern, file_content)
    score_result = re.findall(score_pattern, file_content)
    try:
        with open(acq_file, 'w', newline='') as csvfile:
            fieldnames = ['Test', 'Severity', 'Regulations', 'Result', 'Category', 'Description', 'Remediation', 'CVELink', 'Details', 'Data', 'Score']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for i in range(len(test_result)):
                writer.writerow({'Test': test_result[i],
                                'Severity': severity_result[i],
                                'Regulations': regulations_result[i],
                                'Result': result_result[i],
                                'Category': category_result[i],
                                'Description': description_result[i],
                                'Remediation': remediation_result[i],
                                'CVELink': cveLink_result[i],
                                'Details': details_result[i],
                                'Data': data_result[i],
                                'Score': score_result[i]
                                })
    except:
        print("Run script as administrator")
        exit(1)


if __name__ == "__main__":
    num_args = len(sys.argv)
    if num_args != 2:
        print("Usage: Scuba2CSV.py <pathToAssessmentResult.js>")
        exit(1)
    file = open(sys.argv[1], "r")
    parse_file(file.read())
