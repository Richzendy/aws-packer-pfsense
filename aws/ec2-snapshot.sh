#!/bin/bash

TIMESTAMP="$(date +%Y%M%d_%H%M%S)"

if [[ ${1} == "" ]]; then
	echo "Usage: ${0} qemu|vbox"
	exit 1
else
	BUILDER=${1}
fi

source aws.conf

# print command for configuring the aws profile 
echo "aws configure --profile ${PROFILE}"

IMAGE="$(ls -1tr ../output-${BUILDER}/ | tail -n1)"

echo "Copy image to S3 Bucket ..."
aws s3 cp --profile ${PROFILE} ../output-${BUILDER}/${IMAGE} s3://${BUCKET}/${IMAGE}

IMAGEFORMAT="$(echo ${IMAGE} | rev | cut -d "." -f1 | rev)"
IMPORTSNAPSHOT="import-snapshot_${TIMESTAMP}.json"

cp import-snapshot.json ${IMPORTSNAPSHOT}
sed -i s/FORMAT_PLACEHODLER/${IMAGEFORMAT}/g ${IMPORTSNAPSHOT}
sed -i s/BUCKET_PLACEHODLER/${BUCKET}/g ${IMPORTSNAPSHOT}
sed -i s/IMAGE_PLACEHODLER/${IMAGE}/g ${IMPORTSNAPSHOT}

echo "Import image as EC2 snapshot ..."
# print output to stdout, capture ImporTaskId
IMPORTTASKID=$(aws ec2 --profile ${PROFILE} import-snapshot --disk-container file://${IMPORTSNAPSHOT} | tee /dev/tty | grep ImportTaskId | cut -d \" -f 4)

# print command for following snapshot import status
echo "Check when the snapshot is ready with the command below."
echo aws ec2 --profile ${PROFILE} describe-import-snapshot-tasks --import-task-id ${IMPORTTASKID}

# Cannot tag the snapshot like this, beause there would need to be some process to check if the import is ready or not.
#echo "Tagging the snapshot name if jq is installed."
## If jq is installed, print get snapshot ID and tag name into the snapshot
#if command -v "jq" &> /dev/null
#then
#    SNAPSHOTID=$(aws ec2 --profile ${PROFILE} describe-import-snapshot-tasks \
#        --import-task-id ${IMPORTTASKID} | jq -r '.ImportSnapshotTasks[].SnapshotTaskDetail.SnapshotId')
#
#    SNAPSHOTNAME="$(echo ${IMAGE} | rev | cut -d "." -f2- | rev)"
#
#    aws ec2 create-tags --resources "$SNAPSHOTID" --tags Key=Name,Value=${SNAPSHOTNAME}
#else
#    echo "jq is not installed. The snapshot's name is not tagged automatically."
#fi

echo ""
echo "When the import is ready, you can tag the snapshot with command below. Remember to change the value of SNASHOTID."
echo aws ec2 create-tags --resources SNAPSHOTID --tags Key=Name,Value=${SNAPSHOTNAME}

rm ${IMPORTSNAPSHOT}
