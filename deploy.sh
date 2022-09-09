# /bin/zsh
az deployment sub create --name deployment1 --location $1 --template-file main.bicep --parameters @parameters.json 