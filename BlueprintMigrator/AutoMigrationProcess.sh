#!/bin/bash

# This script will auto migrate the blueprints from one VRA instance to another
echo $1
. $1

echo "AppLocation: "$AppLocation
echo "ExportFileLocaton: "$ExportFileLocaton
echo "vraInstance: "$vraInstance
echo "Blueprint File Name: "$BluePrintFileName

# if $AppLocation doesn't exist then create it
if [ ! -d "${AppLocation%$'\r'}" ]
then
mkdir /apps/devportal/Bosh
else
cd /apps/devportal/Bosh
echo "AppLocation Already present"
fi

# if $ExportFileLocaton doesn't exist then create it
if [ ! -d "${ExportFileLocaton%$'\r'}" ]
then
mkdir exportFile
else
echo "ExportFileLocaton Already present"
fi

echo "Starting the migration process"
echo "Extracting the Blueprint IDs and Name"

java -cp CloudClient_lib/ -jar CloudClient.jar $1

echo "Extracting of Blueprint Name and IDs is Complete"
#echo grep -w -f $BluePrintFileName /apps/devportal/Bosh/list_content_CSV_JAVA.csv > blueprintDetails.txt 
grep -w -f /apps/devportal/config/pattern.txt /apps/devportal/Bosh/list_content_CSV_JAVA.csv > blueprintDetails.txt 
cut -d ',' -f 1,2 blueprintDetails.txt > blueprintID_Name.txt
#value=$(<blueprintID_Name.txt)
echo "Extracted Blueprint and Name"
while read -r line
do
    value="$line"
    echo "Extracted Data - $value"
	BlueprintID=$(cut -d ',' -f 1 <<< $value)
	BlueprintName=$(cut -d ',' -f 2 <<< $value)
	echo "Blueprint ID : $BlueprintID"
	echo "BluePrint Name : $BlueprintName"
	
	#Exporting blueprint as zip(with password):
	java -cp CloudClient.jar com.vmware.cloudclient.CloudClientExportor $BlueprintID $BlueprintName $1

	#Getting VRA token	
	echo curl --insecure -H Accept:application/json -H Content-Type:application/json -d '{"username":"'"${ToUsername%$'\r'}"'","password":"'"${ToPassword%$'\r'}"'","tenant":"'"${ToTenantname%$'\r'}"'"}' "${vraInstance%$'\r'}"/identity/api/tokens
	curl --insecure -H Accept:application/json -H Content-Type:application/json -d '{"username":"'"${ToUsername%$'\r'}"'","password":"'"${ToPassword%$'\r'}"'","tenant":"'"${ToTenantname%$'\r'}"'"}' "${vraInstance%$'\r'}"/identity/api/tokens|grep id|cut -d ':' -f5|cut -d "," -f1 >> /apps/devportal/Bosh/token.txt
	fullResponse=$(<token.txt)
	#echo "$fullResponse"
	#echo "VRA TOKEN un-extracted : $fullResponse"
	vratoken="${fullResponse//\"}"
	echo "VRA TOken : $vratoken" 
		
	cd /apps/devportal/Bosh/exportFile
	
	echo "Validating the Blueprint zip ....."
	curl --insecure -s -H Content-Type:multipart/form-data -H Authorization:Bearer\ "$vratoken" "${vraInstance%$'\r'}"/content-management-service/api/packages/validate -F file=@$BlueprintName-composite-blueprint.zip
	
	echo "Migrating the zip file............"
	curl --insecure -s -H Content-Type:multipart/form-data -H Authorization:Bearer\ "$vratoken" "${vraInstance%$'\r'}"/content-management-service/api/packages -F file=@$BlueprintName-composite-blueprint.zip
	
	#delete the temporary files
	rm -f $BlueprintName-composite-blueprint.zip
	cd /apps/devportal/Bosh
	rm -f blueprintDetails.txt blueprintID_Name.txt list_content_CSV_JAVA.csv token.txt 
	
done < blueprintID_Name.txt