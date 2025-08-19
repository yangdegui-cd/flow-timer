import type { ToastServiceMethods } from "primevue/toastservice";

export const clipboard = (value: string, toast: ToastServiceMethods) => {
  if (navigator.clipboard) {
    navigator.clipboard.writeText(value).then(() => {
      toast?.add({
        severity: "success",
        summary: "已将内容复制到剪贴板",
        life: 3000,
      });
    }).catch((error) => {
      console.error("复制失败:", error);
      toast?.add({
        severity: "error",
        summary: "无法将内容复制到剪贴板",
        life: 3000,
      });
    });
  } else {
    console.warn("浏览器不支持剪贴板API");
    toast?.add({
      severity: "warn",
      summary: "您的浏览器不支持剪贴板API",
      life: 3000,
    });
  }
}

export default clipboard
