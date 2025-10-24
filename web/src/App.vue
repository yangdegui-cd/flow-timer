<script setup lang="ts">
import { onMounted } from 'vue';
import { changePrimaryColor } from "@/utils/changePrimaryColor";

// 初始化主题设置
const initializeTheme = () => {
  // 从localStorage加载设置
  const savedSettings = localStorage.getItem('systemSettings');
  let theme = 'light';
  let primaryColor = 'indigo';
  
  if (savedSettings) {
    try {
      const settings = JSON.parse(savedSettings);
      theme = settings.theme || 'light';
      primaryColor = settings.primaryColor || 'indigo';
    } catch (e) {
      console.warn('Failed to parse saved settings');
    }
  }
  
  // 应用主题模式
  const html = document.documentElement;
  if (theme === 'dark') {
    html.classList.add('dark');
  } else if (theme === 'light') {
    html.classList.remove('dark');
  } else if (theme === 'auto') {
    // 跟随系统
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (prefersDark) {
      html.classList.add('dark');
    } else {
      html.classList.remove('dark');
    }
  }
  
  // 应用主题颜色
  changePrimaryColor(primaryColor);
  
  // 监听系统主题变化（仅在auto模式下）
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (theme === 'auto') {
      if (e.matches) {
        html.classList.add('dark');
      } else {
        html.classList.remove('dark');
      }
    }
  });
};

onMounted(() => {
  initializeTheme();
});
</script>

<template>
  <router-view></router-view>
  <Toast />
  <ConfirmDialog></ConfirmDialog>
</template>

<style>
</style>
