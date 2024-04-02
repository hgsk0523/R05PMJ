import json
import boto3
import ast
import pymysql
import os
import datetime

def lambda_handler(event, context):
    try:
        #レスポンスのヘッダ
        HEADERS = {
            "content-type": "application/json; charset=UTF-8",
            "Content-Security-Policy": "default-src 'self'",
            "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
            "Cache-Control": "no-store",
            "X-Content-Type-Options": "nosniff"
        }
        
        #処理結果コード
        result_code = 50004
        
        #点検名情報リスト
        inspection_names = []
        
        #RDSProxyへの接続情報を取得する
        rds_proxy_connection_info = get_rds_proxy_connection_info();
            
        #点検マスタテーブルからレコードを取得
        result_code = 50000
        inspection_names = do_select(rds_proxy_connection_info)
            
        result_code = 20000
        return {
            "statusCode": 200,
            "headers": HEADERS,
            "body":json.dumps(
                {
                    "resultCode": result_code,
                    "inspectionNames": inspection_names
                }
            )
        }
    except Exception as ex:
        print("エラー：", ex)
        return {
            "statusCode": 500,
            "headers": HEADERS,
            "body":json.dumps(
                {
                    "resultCode": result_code,
                    "inspectionNames": inspection_names
                }
            )
        }

#RDSProxyへの接続情報を取得する
def get_rds_proxy_connection_info():
    rds_proxy_connection_info = {
        "db_host":"",
        "db_user":"",
        "db_password":"",
        "db_name":""
    }
    
    #SecretsManagerからRDSProxy接続情報を取得
    SECRET_NAME = os.environ["SECRET_NAME"]
    REGION_NAME = os.environ["REGION_NAME"]
    session = boto3.session.Session()
    client = session.client(
        service_name="secretsmanager",
        region_name=REGION_NAME
    )
    
    get_secret_value = client.get_secret_value(
        SecretId=SECRET_NAME
    )
    if "SecretString" in get_secret_value:
        secret_data = get_secret_value['SecretString']
        secret = ast.literal_eval(secret_data)
        rds_proxy_connection_info["db_host"] = secret[os.environ["DB_HOST_KEY"]]
        rds_proxy_connection_info["db_user"] = secret[os.environ["DB_USER_KEY"]]
        rds_proxy_connection_info["db_password"] = secret[os.environ["DB_PASSWORD_KEY"]]
        rds_proxy_connection_info["db_name"] = secret[os.environ["DB_NAME_KEY"]]
    
    return rds_proxy_connection_info
    
#点検マスタテーブルからレコードを取得
def do_select(rds_proxy_connection_info):
    inspection_names = []
    
    #DBへ接続
    connect = pymysql.connect(
        host = rds_proxy_connection_info["db_host"],
        user = rds_proxy_connection_info["db_user"], 
        password = rds_proxy_connection_info["db_password"], 
        database = rds_proxy_connection_info["db_name"], 
        cursorclass = pymysql.cursors.DictCursor
    )
    
    with connect.cursor() as cursor:
        sql = """\
            SELECT
                inspection_name_id
                , inspection_name
            FROM
                TBL_M_INSPECTION
        """

        print("sql文：" + sql)
        cursor.execute(sql)
        
        inspection_names = cursor.fetchall()
        print("点検名情報：", inspection_names)
    
    return inspection_names