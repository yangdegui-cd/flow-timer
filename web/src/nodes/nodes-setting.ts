import type { NodeSetting } from "./type.ts";
import ftp_transfer from "@/nodes/setting/ftp-transfer";
import flow_params from "@/nodes/setting/flow-params";
import upload_cos from "@/nodes/setting/upload-cos";
import input_file from "@/nodes/setting/input-file";
import input_hdfs from "@/nodes/setting/input-hdfs";
import input_kafka from "@/nodes/setting/input-kafka";
import input_mysql from "@/nodes/setting/input-mysql";
import input_cos from "@/nodes/setting/input-cos";
import output_file from "@/nodes/setting/output-file";
import output_hdfs from "@/nodes/setting/output-hdfs";
import output_kafka from "@/nodes/setting/output-kafka";
import output_mysql from "@/nodes/setting/output-mysql";
import data_transition from "@/nodes/setting/data-transition";
import data_merge from "@/nodes/setting/data-merge";
import data_filter from "@/nodes/setting/data-filter";
import data_order from "@/nodes/setting/data-order";
import file_compress from "@/nodes/setting/flie-compress";
import send_email from "@/nodes/setting/send-email";
import execute_sql from "@/nodes/setting/execute-sql";

const nodes_setting: Record<string, NodeSetting> = {
  data_filter,
  data_merge,
  data_transition,
  data_order,
  flow_params,
  ftp_transfer,
  input_cos,
  input_file,
  input_hdfs,
  input_kafka,
  input_mysql,
  output_file,
  output_hdfs,
  output_kafka,
  output_mysql,
  upload_cos,
  file_compress,
  send_email,
  execute_sql
}

export default nodes_setting
