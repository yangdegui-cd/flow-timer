const ftp_transfer = {
  view: {
    icon: "ftp",
    icon_type: "custom",
    name: "FTP传输",
    node_type: "common"
  },
  init: {
    source_setting: {
      source_type: "custom",
      host_setting: {
        host: "",
        port: 22,
        username: "",
        authentication_type: "password",
        password: "",
        pem: "",
      },
      choose_host: null,
      files: [],
      multifile_merge: true,
      use_original_name: false,
      use_zip: false,
      tmp_folder: null,
      file_name: null,
    },
    target_setting: {
      source_type: "custom",
      host_setting: {
        host: "",
        port: 22,
        username: "",
        authentication_type: "password",
        password: "",
        pem: "",
      },
      choose_host: null,
      folder: "",
    }
  },
}

export default ftp_transfer;
