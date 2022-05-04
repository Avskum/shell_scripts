#Enforces that it be executed with superuser (root) privileges.
#If the script is not executed with superuser privileges it will not attempt to create a user and returns an exit status of 1.


MY_UID=${UID}
if [[ $MY_UID -eq 0 ]]
then
  echo 'executing script as root'
else
  echo 'script should be executed with super user rights'
  exit 1
fi
#Prompts the person who executed the script to enter the username (login), the name for person who will be using the account, and the initial password for the account.
#ask for user Name
read -p 'Enter username: ' USER_NAME
#ask for real name
read -p 'Enter real name: ' COMMENT
#ask for password
read -p 'Enter password: ' PASSWORD

#Creates a new user on the local system with the input provided by the user.

#create user
if [[ "${?} -ne 0" ]]
then
adduser -c "${COMMENT}" -m ${USER_NAME}
#set password
echo ${PASSWORD} | passwd --stdin ${USER_NAME}
#force user change password
passwd -e ${USER_NAME}
  exit 0
else
  exit 1
fi
#Informs the user if the account was not able to be created for some reason.  If the account is not created, the script is to return an exit status of 1.
echo "created user with parameters metioned below >>>>
username: ${USER_NAME}
real name: "${COMMENT}"
password: ${PASSWORD}
Send this info to the user!"
#Displays the username, password, and host where the account was created.  T
#his way the help desk staff can copy the output of the script in order to easily deliver the information to the new account holder.
