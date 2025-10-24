import type { UploadCosConfig } from '@/data/types/cos-types'
import { createUploadCosConfigDefaults } from '@/data/defaults/cos-defaults'

const upload_cos = {
  view: {
    icon: "cos",
    icon_type: "custom",
    name: "上传COS",
    node_type: "common",
    node_subtype: "upload_cos",
    hide_source: false,
    hide_target: false,
  },
  init: createUploadCosConfigDefaults(),
  config: {}
}

export default upload_cos;
