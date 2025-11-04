import type { ToastServiceMethods } from "primevue/toastservice";

export const clipboard = (value: string, toast: ToastServiceMethods) => {
  if (navigator.clipboard) {
    navigator.clipboard.writeText(value).then(() => {
      toast?.add({ severity: "success", summary: "已将内容复制到剪贴板", detail: value, life: 3000 });
    }).catch((error) => {
      console.error("复制失败:", error);
      toast?.add({ severity: "error", summary: "无法将内容复制到剪贴板", life: 3000 });
    });
  } else {
    try {
      copyWithExecCommand(value, toast);
    }catch {
      toast?.add({ severity: "warn", summary: "您的浏览器不支持剪贴板API", life: 3000 });
    }
  }
}

const copyWithExecCommand = (value: string, toast: ToastServiceMethods) => {
  const textArea = document.createElement('textarea');
  textArea.value = value;

  textArea.style.position = 'fixed';
  textArea.style.opacity = '0';

  document.body.appendChild(textArea);
  textArea.select();
  textArea.setSelectionRange(0, 99999); // 对于移动设备的一些兼容处理

  const successful = document.execCommand('copy');
  document.body.removeChild(textArea);
  if (successful) {
    toast?.add({ severity: "success", summary: "已将内容复制到剪贴板", detail: value, life: 3000 });
  } else {
    throw new Error('execCommand 执行失败');
  }
}

export default clipboard
