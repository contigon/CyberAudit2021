# CyberAudit2021
Cyber Audit Tool 2021

<h3> The Project Continuos Deployment Process Description </h3>

<h4> Participated Repositories: </h4>
<li> https://github.com/contigon/CyberAudit2021 (Private) </li>
<li> https://github.com/contigon/CATInstall (Public) </li>

<h4> Actively Related Files: </h4>
<li> contigon/CyberAudit2021/.github/workflows/main.yaml </li>
<li> contigon/CyberAudit2021/deployCAT.ps1 </li>
<li> contigon/CATInstall/go.pdf </li>

<h4>The Process Flow:</h4>

1. On push into main branch, the main.yaml file is called and the 'deploy' job is executed by a new clean windows host, assigned by github.
2. The deploy job runs the <b>CyberAudit2021/deployCAT.ps1</b> script.
3. The above script does the following:
<ul>
3.1. Creates local new working directory on the assigned windows machine. 
</ul>
<ul>3.2. Connects github with projects contributor credentials and access token which generated in advance.</ul>
<ul>3.3. Clones the main branch of CyberAudit2021 project into the working directory.
</ul>
<ul>3.4. Clones the main branch of CATInstall project into the working directory.
</ul>
<ul>3.5. Removes the script file deployCAT.ps1 and the .git folder (which includes the access token) from the CyberAudit2021 folder.
</ul>
<ul>3.6. Now the CyberAudit2021 folder is compressed into a file called 'go.pdf'.
</ul>
<ul>3.7. The abobe pdf file is copied and overwrites the older one inside the CATInstall folder.
</ul>
<ul>3.8. Then the go.pdf file is commited and pushed upstream to the CATInstall remote repository.
</ul>
<ul>3.9. Removes recursively the local working directory with its content.
</ul>
4. The CAT project is now deployed and ready to be downloaded as 'go.pdf' in https://github.com/contigon/CATInstall
