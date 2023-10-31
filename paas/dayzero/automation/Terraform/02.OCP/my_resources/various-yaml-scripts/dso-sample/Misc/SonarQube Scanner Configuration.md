# SonarQube

_Prerequisites:_ A "@digital.mod.uk" Google ID has been created, or login credentials have been supplied for access to the platform.

Login page:  https://sonarqube-https-dso-tooling-sonar.apps.ocp1.azure.dso.digital.mod.uk/

![image](https://user-images.githubusercontent.com/90788425/150103575-196c0e8a-9091-4fb6-88b9-e15ac665ad29.png)

### Creating a project

In order to create a project, users will need to be in the correct group, or be added to the group, by an administrator.

Click on my account -> profile

![image](https://user-images.githubusercontent.com/90788425/150103947-e6d41a5e-b731-46e7-b478-77e1acde19c8.png)

Click on project -> new project

![image](https://user-images.githubusercontent.com/90788425/150114393-e772bccf-3ea8-4a66-ace6-0ee696a9dbb8.png)

For example:

![image](https://user-images.githubusercontent.com/90788425/150114422-6ce40dda-7ffa-4146-a56e-01c8510e29be.png)

Next you will want to generate a token for the project.

Click on my account -> security

![image](https://user-images.githubusercontent.com/90788425/150114558-512db36b-87dc-4332-9ae0-6c19ce4c166d.png)

Once done, it should look something like below:

![image](https://user-images.githubusercontent.com/90788425/150114617-61e5dd85-3722-4323-8bf1-bf630da61f9a.png)

### Sonar-project.properties file

In order to use SonarQube in your pipeline, you will need to create a _sonar-project.properties_ file and include it at the top level of your source code repository.

The file should follow the format shown below:

<img width="740" alt="Screenshot 2022-01-19 at 10 46 06" src="https://user-images.githubusercontent.com/90788425/150115223-ba2c159a-4bd9-4f50-84d1-1c12ea13d129.png">

The pipeline should then be updated accordingly with the relevant parameter values.

### SonarQube Dashboard.

Once the pipeline has been successfully run, the dashboard should look something like this:

![image](https://user-images.githubusercontent.com/90788425/150115494-5b768969-7d74-4866-9e48-d62a62df5dc7.png)

### Quality Gate

In order to add a quality gate to SonarQube, simply do the following:

![image](https://user-images.githubusercontent.com/90788425/150115576-515ca99d-a24e-4353-a3c1-1e0b2e87a5c7.png)







