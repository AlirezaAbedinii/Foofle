import mysql.connector
from tabulate import tabulate
import time
def show_actions():
    print("Enter the action number you want to do")
    print("1.   modify another user access mode")
    print("2.   delete account")
    print("3.   delete email")
    print("4.   get your information")
    print("5.   get notifications")
    print("6.   get another user personal information")
    print("7.   log in")
    print("8.   read email")
    print("9.   send email")
    print("10.  get sent emails")
    print("11.  get received emails")
    print("12.  sign in")
    print("13.  update information")
    print("14.  quit")

def give_permission():
    mycursor = mydb.cursor()
    try :
        print("Enter username of the person you want to specify his access mode")
        to_acc = input()
        print("Enter 1 to give permission and 0 to not give")
        permit = int(input())

        args = [to_acc,permit]
        result = mycursor.callproc("add_permission",args)
        mydb.commit()
        print(result)
    except :
        print("BAD INPUT")
    mycursor.close()

def delete_account():
    mycursor = mydb.cursor()
    mycursor.callproc("delete_account")
    mydb.commit()
    print('Your account deleted successfully')
    mycursor.close()

def delete_mail():
    mycursor = mydb.cursor()
    try:
        print("Enter email ID")
        ID = int(input())
        args = [ID]
        result = mycursor.callproc("delete_mail", args)
        mydb.commit()
        print("DONE")
    except:
        print("BAD INPUT")
    mycursor.close()

def get_info():
    mycursor = mydb.cursor()
    mycursor.callproc("get_information")
    for res in mycursor.stored_results():
        print(tabulate(res, headers=['username', 'password','create_time',
                                     'birthdate','phone_number',
                                     'account_phone_number','address',
                                     'first_name','last_name','nickname',
                                     'personal_ID','access_mode'], tablefmt='psql'))

    mycursor.close()

def get_notif():
    mycursor = mydb.cursor()
    mycursor.callproc("get_notifications")
    for res in mycursor.stored_results():
        print(tabulate(res, headers=['notifications', 'time'], tablefmt='psql'))

    mycursor.close()

def get_personal_info():
    mycursor = mydb.cursor()
    print('Enter the username you want to get information from')
    name = input()
    args=[name]
    mycursor.callproc("get_personal_info",args)
    for res in mycursor.stored_results():

        print(tabulate(res, headers=['address', 'first_name','last_name','phone_number',
                                     'birthdate','nickname','personal_id'], tablefmt='psql'))

    mycursor.close()

def log_in():
    mycursor = mydb.cursor()
    try:
        print("Enter username")
        username = input()
        print('enter password')
        password = input()
        state = ''
        args = [username,password,0]
        result = mycursor.callproc("log_in", args)
        print(result[2])
        mydb.commit()
        #print("DONE")
    except:
        print("BAD INPUT")
    mycursor.close()

def read_mail():
    mycursor = mydb.cursor()
    try:
        print("Enter email ID")
        ID = int(input())
        args = [ID,0]
        result = mycursor.callproc("read_mail", args)
        mydb.commit()
        print(result[1])
    except:
        print("BAD INPUT")
    mycursor.close()

def send_mail():
    mycursor = mydb.cursor()
    try:
        print("Enter subject,context,three receivers,three cc receivers separated by comma")
        print("(receivers can be the same)")
        email_input = input()
        args = email_input.split(',')
        args.append(0)
        result = mycursor.callproc("send_mail", args)
        mydb.commit()
        print(result[8])
    except:
        print("BAD INPUT")
    mycursor.close()

def get_sent_emails():
    mycursor = mydb.cursor()
    print("Enter page number and items per page separated by comma")
    print("(pages start from index 0)")
    inp = input()
    args = inp.split(',')
    mycursor.callproc("sent_emails",args)
    for res in mycursor.stored_results():
        print(tabulate(res, headers=['email_ID','subject','sent_time','context','sender','is read'], tablefmt='psql'))

    mycursor.close()

def get_received_emails():
    mycursor = mydb.cursor()
    print("Enter page number and items per page separated by comma")
    print("(pages start from index 0)")
    inp = input()
    args = inp.split(',')
    mycursor.callproc("show_received_emails", args)
    for res in mycursor.stored_results():
        print(tabulate(res, headers=['email_ID', 'subject', 'sent_time', 'context', 'receiver','is_cc', 'is read'],
                       tablefmt='psql'))

    mycursor.close()

def update_info():
    mycursor = mydb.cursor()
    try:
        print("Enter password,birthdate(yyyy-mm-dd hh:mm:ss),phone number,"
              "account number,address,firstname,lastname,nickname,"
              "personal ID,and default access mode(1 or 0) separated by comma")
        # print("(receivers can be the same)")
        email_input = input()
        args = email_input.split(',')
        args[9] = int(args[9])
        args.append(0)
        result = mycursor.callproc("update_information", args)
        mydb.commit()
        print(result[10])
    except:
        print("BAD INPUT")
    mycursor.close()

def sign_in():
    mycursor = mydb.cursor()
    try:
        print("Enter username,password,birthdate(yyyy-mm-dd hh:mm:ss),phone number,"
              ",account number,address,firstname,lastname,nickname,"
              ",personal ID,and default access mode(1 or 0) separated by comma")
        #print("(receivers can be the same)")
        email_input = input()
        args = email_input.split(',')
        args[10] = int(args[10])
        args.append(0)
        result = mycursor.callproc("sign_in", args)
        mydb.commit()
        print(result[11])
    except:
        print("BAD INPUT")
    mycursor.close()

# connect to data base
mydb = mysql.connector.connect(
    host = "localhost",
    user = "root",
    passwd = "",
    database = "testdb"
)

#start
while True:
    show_actions()
    n = int(input())
    if n == 1:
        give_permission()
    elif n == 2:
        delete_account()
    elif n == 3:
        delete_mail()
    elif n == 4:
        get_info()
    elif n == 5:
        get_notif()
    elif n == 6:
        get_personal_info()
    elif n == 7:
        log_in()
    elif n == 8:
        read_mail()
    elif n == 9:
        send_mail()
    elif n == 10:
        get_sent_emails()
    elif n == 11:
        get_received_emails()
    elif n == 12:
        sign_in()
    elif n == 13:
        update_info()
    elif n == 14:
        break
    else:
        print("BAD ACTION, TRY AGAIN")

    time.sleep(2)



