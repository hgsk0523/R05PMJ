import json
import boto3
import ast
import pymysql
import os
import datetime
from botocore.client import Config
import uuid
import io
import zipfile
from zipfile import ZipFile

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
        
        #点検結果情報リスト
        inspection_item_results = []
        inspection_results = []
        
        #点検項目のPre-SignedURL
        inspection_item_results_url = ""
        #点検結果情報のPre-SignedURL
        inspection_results_url = ""
        
        #クエリパラメータを取得
        inspection_name_id = ""
        wscd = ""
        start_date = ""
        end_date = ""
        output_count = ""
        
        queryStringParams = event["queryStringParameters"]
        if queryStringParams is not None:
            for param in queryStringParams:
                match param:
                    case "inspectionNameId":
                        inspection_name_id = queryStringParams["inspectionNameId"]
                    
                    case "wscd":
                        wscd = queryStringParams["wscd"]
                    
                    case "startDate":
                        start_date = queryStringParams["startDate"]
                        
                    case "endDate":
                        end_date = queryStringParams["endDate"]
                        
                    case "outputCount":
                        output_count = queryStringParams["outputCount"]
                    
                    case _:
                        result_code = 40002
                        return {
                            "statusCode": 400,
                            "headers": HEADERS,
                            "body":json.dumps(
                                {
                                    "resultCode": result_code,
                                    "inspectionItemResultsUrl" : inspection_item_results_url,
                                    "inspectionResultsUrl" : inspection_results_url
                                }
                            )
                        }
        
        print("クエリパラメータ　inspectionNameId：" + inspection_name_id + ", wscd：" + wscd + ", startDate：" + start_date + ", endDate：" + end_date + ", outputCount:" + output_count)
        #クエリパラメータの必須チェック
        if inspection_name_id == "" or start_date == "" or end_date == "" or output_count == "":
            result_code = 40000
            return {
                "statusCode": 400,
                "headers": HEADERS,
                "body":json.dumps(
                    {
                        "resultCode": result_code,
                        "inspectionItemResultsUrl" : inspection_item_results_url,
                        "inspectionResultsUrl" : inspection_results_url
                    }
                )
            }
        
        #点検名IDの型チェック
        if not validate_inspection_name_id(inspection_name_id):
            result_code = 40001
            return {
                "statusCode": 400,
                "headers": HEADERS,
                "body":json.dumps(
                    {
                        "resultCode": result_code,
                        "inspectionItemResultsUrl" : inspection_item_results_url,
                        "inspectionResultsUrl" : inspection_results_url
                    }
                )
            }
        
        #wscdのチェック
        if not validate_wscd(wscd):
            result_code = 40001
            return {
                "statusCode": 400,
                "headers": HEADERS,
                "body":json.dumps(
                    {
                        "resultCode": result_code,
                        "inspectionItemResultsUrl" : inspection_item_results_url,
                        "inspectionResultsUrl" : inspection_results_url
                    }
                )
            }
        
        #日付の型チェック
        if not validate_date(start_date, end_date):
            result_code = 40001
            return {
                "statusCode": 400,
                "headers": HEADERS,
                "body":json.dumps(
                    {
                        "resultCode": result_code,
                        "inspectionItemResultsUrl" : inspection_item_results_url,
                        "inspectionResultsUrl" : inspection_results_url
                    }
                )
            }
        
        #出力件数の型チェック
        if not validate_output_count(output_count):
            result_code = 40001
            return {
                "statusCode": 400,
                "headers": HEADERS,
                "body":json.dumps(
                    {
                        "resultCode": result_code,
                        "inspectionItemResultsUrl" : inspection_item_results_url,
                        "inspectionResultsUrl" : inspection_results_url
                    }
                )
            }

        #RDSProxyへの接続情報を取得する
        rds_proxy_connection_info = get_rds_proxy_connection_info();
            
        #テーブルからレコードを取得
        result_code = 50000
        tmp_results = do_select(inspection_name_id, wscd, start_date, end_date, output_count, rds_proxy_connection_info)
        inspection_item_results = tmp_results[0]
        inspection_results = tmp_results[1]
        
        #取得したレコードをS3にjsonファイルで出力し、Pre-SignedURLを発行する
        result_code = 50002
        REGION_NAME = os.environ["REGION_NAME"]
        S3_BUCKET_NAME = os.environ["S3_BUCKET_NAME"]
        S3_URL_EXPIRES_IN_SECONDS = int(os.environ["S3_URL_EXPIRES_IN_SECONDS"])
        BASE_FILE_NAME = str(uuid.uuid4())
        S3_JSON_FOLDER_PATH = os.environ["S3_JSON_FOLDER_PATH"]
        s3 = boto3.client("s3", region_name = REGION_NAME, config = Config(signature_version="s3v4"))
        
        print("zip圧縮開始")
        zip_stream = io.BytesIO()
        with zipfile.ZipFile(zip_stream, 'w', compression=zipfile.ZIP_DEFLATED) as z:
            with z.open("inspection_results.json", "w") as d:
                d.write(json.dumps(inspection_results).encode('utf-8'))
        print("zip圧縮終了")
        
        #点検項目をjsonファイル出力
        s3.put_object(
            Body=json.dumps(inspection_item_results),
            Bucket = S3_BUCKET_NAME,
            Key = S3_JSON_FOLDER_PATH + "inspection_item_results_" + BASE_FILE_NAME + ".json"
        )
        #点検項目のPre-SignedURLを発行する
        inspection_item_results_url = s3.generate_presigned_url(
            ClientMethod = "get_object",
            Params = {"Bucket" : S3_BUCKET_NAME, "Key" : S3_JSON_FOLDER_PATH + "inspection_item_results_" + BASE_FILE_NAME + ".json"},
            ExpiresIn = S3_URL_EXPIRES_IN_SECONDS,
            HttpMethod = "GET"
        )
        #点検スケジュールをzファイル出力
        s3.put_object(
            Body=zip_stream.getvalue(),
            Bucket = S3_BUCKET_NAME,
            Key = S3_JSON_FOLDER_PATH + "inspection_results_" + BASE_FILE_NAME + ".zip",
            ContentType = "application/zip",
            Metadata = {"count": str(len(inspection_results))}
        )
        #点検スケジュールのPre-SignedURLを発行する
        inspection_results_url = s3.generate_presigned_url(
            ClientMethod = "get_object",
            Params = {"Bucket" : S3_BUCKET_NAME, "Key" : S3_JSON_FOLDER_PATH + "inspection_results_" + BASE_FILE_NAME + ".zip"},
            ExpiresIn = S3_URL_EXPIRES_IN_SECONDS,
            HttpMethod = "GET"
        )
        
        result_code = 20000
        return {
            "statusCode": 200,
            "headers": HEADERS,
            "body":json.dumps(
                {
                    "resultCode": result_code,
                    "inspectionItemResultsUrl" : inspection_item_results_url,
                    "inspectionResultsUrl" : inspection_results_url
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
                    "inspectionItemResultsUrl" : inspection_item_results_url,
                    "inspectionResultsUrl" : inspection_results_url
                }
            )
        }

#点検名IDの型チェック
def validate_inspection_name_id(inspection_name_id):
    try:
        tmp_inspection_name_id = int(inspection_name_id)
        return True
    except:
        return False
        
#wscdのチェック
def validate_wscd(wscd):
    if len(wscd) <= 10:
        return True
    else:
        return False

#日付の型チェック
def validate_date(start_date, end_date):
    try:
        tmp_start_date = datetime.datetime.strptime(start_date, "%Y/%m/%d")
        tmp_end_date = datetime.datetime.strptime(end_date, "%Y/%m/%d")
        return True
    except:
        return False

#出力件数の型チェック
def validate_output_count(output_count):
    try:
        tmp_output_count = int(output_count)
        return True
    except:
        return False
        
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
    
#テーブルからレコードを取得
def do_select(inspection_name_id, wscd, start_date, end_date, output_count, rds_proxy_connection_info):
    inspection_items = []
    inspections = []
    results = []
    
    #DBへ接続
    connect = pymysql.connect(
        host = rds_proxy_connection_info["db_host"],
        user = rds_proxy_connection_info["db_user"], 
        password = rds_proxy_connection_info["db_password"], 
        database = rds_proxy_connection_info["db_name"], 
        cursorclass = pymysql.cursors.DictCursor
    )
    
    with connect.cursor() as cursor:
        #点検項目マスタ
        sql = """\
            SELECT
                item_name_id
                , item_name
                , analysis_type
            FROM
                TBL_M_INSPECTION_ITEM
            WHERE
                inspection_name_id = %s
                AND analysis_type IN (1, 2)
            ORDER BY
                analysis_type, item_name_id
        """
        params = (int(inspection_name_id))
        
        print("sql文：" + sql)
        print("sqlパラメータ：", params)
        cursor.execute(sql, params)
        inspection_items = cursor.fetchall()
        
        #点検スケジュール
        sql = """\
            SELECT
                INS.inspection_name
                , INS.inspection_id
                , INS.worksheet_code
                , INS.inspection_date
                , IFNULL(ITEM.item_name_id, '') AS item_name_id
                , IFNULL(ITEM.analysis_type, '') AS analysis_type
                , IFNULL(ITEM.model, '') AS model
                , IFNULL(ITEM.edited_model, '') AS edited_model
                , IFNULL(ITEM.serial_number, '') AS serial_number
                , IFNULL(ITEM.edited_serial_number, '') AS edited_serial_number
                , IFNULL(ITEM.ai_result, '') AS ai_result
                , IFNULL(ITEM.ng_comment, '') AS ng_comment
                , IFNULL(ITEM.s3_image_path, '') AS s3_image_path
            FROM
                (
                SELECT
                    TBL_M_INSPECTION.inspection_name
                    , TBL_T_INSPECTION.inspection_id
                    , TBL_T_INSPECTION.worksheet_code
                    , DATE_FORMAT(TBL_T_INSPECTION.inspection_date, '%%Y/%%m/%%d') AS inspection_date
                FROM
                    TBL_M_INSPECTION
                INNER JOIN
                    TBL_T_INSPECTION
                ON
                    TBL_M_INSPECTION.inspection_name_id = TBL_T_INSPECTION.inspection_name_id
                    AND TBL_M_INSPECTION.inspection_name_id = %s
                WHERE
                    DATE_FORMAT(TBL_T_INSPECTION.inspection_date, '%%Y/%%m/%%d') BETWEEN %s AND %s
        """
        params = (int(inspection_name_id), start_date, end_date)
        
        if wscd is not None and wscd != "":
            sql += "AND TBL_T_INSPECTION.worksheet_code = %s"
            params = params + (wscd,)
            
        sql += """\
                ORDER BY
                    inspection_date DESC, inspection_id
                LIMIT %s
                ) AS INS
            LEFT OUTER JOIN
                (
                SELECT
                	TBL_M_INSPECTION_ITEM.inspection_name_id
                	, TBL_M_INSPECTION_ITEM.item_name_id
                	, TBL_M_INSPECTION_ITEM.analysis_type
                	, TBL_T_INSPECTION_ITEM.inspection_id
                	, TBL_T_INSPECTION_ITEM.model
                	, TBL_T_INSPECTION_ITEM.edited_model
                	, TBL_T_INSPECTION_ITEM.serial_number
                	, TBL_T_INSPECTION_ITEM.edited_serial_number
                	, TBL_T_INSPECTION_ITEM.ai_result
                	, TBL_T_INSPECTION_ITEM.ng_comment
                	, TBL_T_INSPECTION_ITEM.s3_image_path
                FROM
                	TBL_M_INSPECTION_ITEM
                INNER JOIN
                	TBL_T_INSPECTION_ITEM
                ON
                	TBL_M_INSPECTION_ITEM.item_name_id = TBL_T_INSPECTION_ITEM.item_name_id
                	AND TBL_M_INSPECTION_ITEM.analysis_type IN (1, 2)
                ORDER BY
                    item_name_id
                ) AS ITEM
            ON
                INS.inspection_id = ITEM.inspection_id
            ORDER BY
                INS.inspection_date DESC, inspection_id, analysis_type, item_name_id
        """
        params = params + (int(output_count),)
        
        print("sql文：" + sql)
        print("sqlパラメータ：", params)
        cursor.execute(sql, params)
        inspections = cursor.fetchall()
        
        results = (inspection_items, inspections)
        print("点検項目名、点検結果情報：", results)
    
    return results