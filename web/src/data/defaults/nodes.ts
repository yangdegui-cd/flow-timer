// SQL执行节点默认配置
import { ExecuteSqlNodeSetting } from "@/nodes/setting/execute-sql";

export const SQL_EXECUTE_NODE_DEFAULT: ExecuteSqlNodeSetting = {
  connection_type: 'custom',
  custom_connection: {
    name: '',
    type: 'mysql',
    host: '',
    port: 3306,
    username: '',
    password: '',
    description: ''
  },
  catalog: null,
  database: null,
  schema: null,
  sql: '-- 请输入SQL语句\nSELECT 1 AS test_column;',
  timeout: 300,
  max_rows: 1000,
  output_format: 'json',
  save_result: false,
}

// 上传COS节点默认配置
export interface UploadCosNodeSetting {
  source_setting: {
    source_type: 'custom' | 'metadata' | 'localhost'
    host_setting: {
      host: string
      port: number
      username: string
      authentication_type: 'password' | 'pem'
      password: string
      pem: string
    }
    choose_host: number | null
    files: string[]
    multifile_merge: boolean
    use_original_name: boolean
    use_zip: boolean
    tmp_folder: string | null
    file_name: string | null
  }
  cos_setting: {
    region: string
    secret_id: string
    secret_key: string
    bucket: string
    prefix: string
    storage_class: 'STANDARD' | 'STANDARD_IA' | 'INTELLIGENT_TIERING' | 'ARCHIVE' | 'DEEP_ARCHIVE'
    acl: 'private' | 'public-read' | 'public-read-write'
    overwrite: boolean
    use_ssl: boolean
  }
}

export const UPLOAD_COS_NODE_DEFAULT: UploadCosNodeSetting = {
  source_setting: {
    source_type: 'custom',
    host_setting: {
      host: '',
      port: 22,
      username: '',
      authentication_type: 'password',
      password: '',
      pem: '',
    },
    choose_host: null,
    files: [],
    multifile_merge: true,
    use_original_name: false,
    use_zip: false,
    tmp_folder: null,
    file_name: null,
  },
  cos_setting: {
    region: 'ap-guangzhou',
    secret_id: '',
    secret_key: '',
    bucket: '',
    prefix: '',
    storage_class: 'STANDARD',
    acl: 'private',
    overwrite: true,
    use_ssl: true,
  }
}
