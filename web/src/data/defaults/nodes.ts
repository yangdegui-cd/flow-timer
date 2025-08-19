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
