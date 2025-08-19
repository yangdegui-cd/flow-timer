<template>
  <div class="auth-container min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8 h-screen overflow-auto">
    <!-- 动画背景 -->
    <div class="auth-background">
      <!-- 几何图形层 -->
      <div class="geometric-layer">
        <div class="geometric-shape shape-1"></div>
        <div class="geometric-shape shape-2"></div>
        <div class="geometric-shape shape-3"></div>
        <div class="geometric-shape shape-4"></div>
        <div class="geometric-shape shape-5"></div>
        <div class="geometric-shape shape-6"></div>
        <div class="geometric-shape shape-7"></div>
        <div class="geometric-shape shape-8"></div>
      </div>
      
      <!-- 粒子效果层 -->
      <div class="particles-layer">
        <div class="particle" v-for="i in 40" :key="i" :style="getParticleStyle(i)"></div>
      </div>
      
      <!-- 星空点点层 -->
      <div class="stars-layer">
        <div class="star" v-for="i in 60" :key="i" :style="getStarStyle(i)"></div>
      </div>
      
      <!-- 网格线层 -->
      <div class="grid-layer">
        <div class="grid-lines"></div>
      </div>
      
      <!-- 光束效果层 -->
      <div class="light-beams">
        <div class="beam beam-1"></div>
        <div class="beam beam-2"></div>
        <div class="beam beam-3"></div>
      </div>
      
      <!-- 波纹效果层 -->
      <div class="ripple-layer">
        <div class="ripple ripple-1"></div>
        <div class="ripple ripple-2"></div>
        <div class="ripple ripple-3"></div>
      </div>
    </div>

    <div class="max-w-md w-full space-y-8 relative z-10 form-container">
      <!-- Logo and Title -->
      <div class="text-center">
        <div class="logo-container mx-auto h-20 w-20 flex items-center justify-center bg-primary-500 rounded-full mb-6 backdrop-blur-sm bg-opacity-90 shadow-2xl">
          <i class="pi pi-cog text-3xl text-white logo-icon"></i>
        </div>
      </div>

      <!-- Auth Forms -->
      <div class="mt-8 form-content">
        <!-- Login Form -->
        <LoginForm
          v-if="currentMode === 'login'"
          @switch-to-register="switchToRegister"
        />

        <!-- Register Form -->
        <RegisterForm
          v-else
          @switch-to-login="switchToLogin"
        />
      </div>

      <!-- Footer -->
      <div class="text-center text-sm text-surface-500 footer-text">
        <p>&copy; 2025 Flow Timer. All rights reserved.</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import LoginForm from '@/views/_form/LoginForm.vue'
import RegisterForm from '@/views/_form/RegisterForm.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

// Current mode
const currentMode = ref<'login' | 'register'>('login')

// Switch between login and register
const switchToLogin = () => {
  currentMode.value = 'login'
  router.replace({ name: 'login' })
}

const switchToRegister = () => {
  currentMode.value = 'register'
  router.replace({ name: 'register' })
}

// Generate random particle styles
const getParticleStyle = (index: number) => {
  const size = Math.random() * 6 + 3 // 3-9px
  const left = Math.random() * 100 // 0-100%
  const animationDuration = Math.random() * 25 + 15 // 15-40s
  const animationDelay = Math.random() * 8 // 0-8s
  
  return {
    width: `${size}px`,
    height: `${size}px`,
    left: `${left}%`,
    animationDuration: `${animationDuration}s`,
    animationDelay: `${animationDelay}s`
  }
}

// Generate random star styles
const getStarStyle = (index: number) => {
  const size = Math.random() * 3 + 1 // 1-4px
  const left = Math.random() * 100 // 0-100%
  const top = Math.random() * 100 // 0-100%
  const animationDuration = Math.random() * 4 + 2 // 2-6s
  const animationDelay = Math.random() * 6 // 0-6s
  
  return {
    width: `${size}px`,
    height: `${size}px`,
    left: `${left}%`,
    top: `${top}%`,
    animationDuration: `${animationDuration}s`,
    animationDelay: `${animationDelay}s`
  }
}

// Set initial mode based on route
onMounted(() => {
  if (route.name === 'register') {
    currentMode.value = 'register'
  } else {
    currentMode.value = 'login'
  }

  // 如果已经登录，重定向到首页
  if (authStore.isAuthenticated) {
    const redirect = route.query.redirect as string || '/'
    router.push(redirect)
  }
})
</script>

<style scoped>
.auth-container {
  position: relative;
  background: 
    radial-gradient(circle at 25% 25%, #1a202c 0%, transparent 50%),
    radial-gradient(circle at 75% 75%, #2d3748 0%, transparent 50%),
    linear-gradient(135deg, #0f172a 0%, #1e293b 35%, #2d3748 70%, #4a5568 100%);
  overflow: hidden;
  min-height: 100vh;
  animation: backgroundPulse 12s ease-in-out infinite;
}

.auth-background {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  overflow: hidden;
}

/* 主背景层叠效果 */
.auth-container::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
    radial-gradient(ellipse at 30% 40%, rgba(59, 130, 246, 0.15) 0%, transparent 50%),
    radial-gradient(ellipse at 70% 60%, rgba(147, 51, 234, 0.1) 0%, transparent 50%),
    radial-gradient(circle at 50% 50%, rgba(16, 185, 129, 0.08) 0%, transparent 60%);
  animation: morphingGradient 15s ease-in-out infinite;
}

.auth-container::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
    radial-gradient(circle at 80% 20%, rgba(79, 172, 254, 0.12) 0%, transparent 40%),
    radial-gradient(circle at 20% 80%, rgba(168, 85, 247, 0.1) 0%, transparent 40%);
  animation: morphingGradient 18s ease-in-out infinite reverse;
}

/* 几何图形层 */
.geometric-layer {
  position: absolute;
  width: 100%;
  height: 100%;
}

.geometric-shape {
  position: absolute;
  border-radius: 50%;
  opacity: 0.6;
  filter: blur(1px);
  animation: float 25s infinite ease-in-out;
}

.shape-1 {
  width: 700px;
  height: 700px;
  top: -350px;
  left: -350px;
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.12) 0%, rgba(29, 78, 216, 0.08) 100%);
  animation: floatRotate 30s infinite ease-in-out;
  animation-delay: 0s;
  border-radius: 60% 40% 30% 70% / 60% 30% 70% 40%;
}

.shape-2 {
  width: 450px;
  height: 450px;
  top: 5%;
  right: -225px;
  background: linear-gradient(135deg, rgba(147, 51, 234, 0.1) 0%, rgba(126, 34, 206, 0.08) 100%);
  animation: floatRotate 35s infinite ease-in-out reverse;
  animation-delay: -8s;
  border-radius: 50% 60% 70% 40% / 50% 40% 60% 50%;
}

.shape-3 {
  width: 350px;
  height: 350px;
  bottom: -175px;
  left: 15%;
  background: linear-gradient(135deg, rgba(16, 185, 129, 0.1) 0%, rgba(5, 150, 105, 0.08) 100%);
  animation: floatPulse 25s infinite ease-in-out;
  animation-delay: -15s;
  border-radius: 30% 70% 70% 30% / 30% 30% 70% 70%;
}

.shape-4 {
  width: 250px;
  height: 250px;
  top: 65%;
  right: 25%;
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.1) 0%, rgba(217, 119, 6, 0.08) 100%);
  animation: floatBounce 20s infinite ease-in-out;
  animation-delay: -5s;
  border-radius: 40% 60% 60% 40% / 60% 40% 40% 60%;
}

.shape-5 {
  width: 550px;
  height: 550px;
  bottom: -275px;
  right: -275px;
  background: linear-gradient(135deg, rgba(239, 68, 68, 0.1) 0%, rgba(220, 38, 38, 0.08) 100%);
  animation: floatSway 40s infinite ease-in-out;
  animation-delay: -12s;
  border-radius: 70% 30% 60% 40% / 40% 70% 30% 60%;
}

.shape-6 {
  width: 180px;
  height: 180px;
  top: 12%;
  left: 35%;
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.1) 0%, rgba(147, 51, 234, 0.08) 100%);
  animation: floatSpin 28s infinite linear;
  animation-delay: -20s;
  border-radius: 50% 40% 70% 30% / 60% 50% 40% 70%;
}

.shape-7 {
  width: 120px;
  height: 120px;
  top: 45%;
  left: 5%;
  background: linear-gradient(135deg, rgba(34, 197, 94, 0.08) 0%, rgba(22, 163, 74, 0.06) 100%);
  animation: floatDrift 32s infinite ease-in-out;
  animation-delay: -25s;
  border-radius: 60% 40% 40% 60% / 40% 60% 60% 40%;
}

.shape-8 {
  width: 320px;
  height: 320px;
  top: 20%;
  right: 5%;
  background: linear-gradient(135deg, rgba(6, 182, 212, 0.09) 0%, rgba(8, 145, 178, 0.07) 100%);
  animation: floatOrbit 45s infinite ease-in-out;
  animation-delay: -30s;
  border-radius: 50% 70% 30% 50% / 70% 50% 50% 30%;
}

/* 粒子效果层 */
.particles-layer {
  position: absolute;
  width: 100%;
  height: 100%;
}

.particle {
  position: absolute;
  background: radial-gradient(circle, rgba(255, 255, 255, 0.6) 0%, rgba(147, 197, 253, 0.4) 50%, transparent 80%);
  border-radius: 50%;
  animation: particleFloat 25s infinite linear;
  box-shadow: 0 0 8px rgba(147, 197, 253, 0.3);
}

/* 星空点点层 */
.stars-layer {
  position: absolute;
  width: 100%;
  height: 100%;
}

.star {
  position: absolute;
  background: #fff;
  border-radius: 50%;
  animation: starTwinkle ease-in-out infinite;
  box-shadow: 0 0 6px rgba(255, 255, 255, 0.8);
}

/* 光束效果层 */
.light-beams {
  position: absolute;
  width: 100%;
  height: 100%;
}

.beam {
  position: absolute;
  width: 2px;
  height: 200px;
  background: linear-gradient(to bottom, transparent 0%, rgba(59, 130, 246, 0.6) 50%, transparent 100%);
  border-radius: 1px;
  animation: beamMove infinite linear;
}

.beam-1 {
  left: 20%;
  animation-duration: 8s;
  animation-delay: 0s;
  transform: rotate(15deg);
}

.beam-2 {
  left: 60%;
  animation-duration: 12s;
  animation-delay: -3s;
  transform: rotate(-10deg);
}

.beam-3 {
  left: 80%;
  animation-duration: 10s;
  animation-delay: -6s;
  transform: rotate(25deg);
}

/* 波纹效果层 */
.ripple-layer {
  position: absolute;
  width: 100%;
  height: 100%;
}

.ripple {
  position: absolute;
  border: 2px solid rgba(59, 130, 246, 0.3);
  border-radius: 50%;
  animation: rippleExpand infinite ease-out;
}

.ripple-1 {
  top: 30%;
  left: 70%;
  animation-duration: 4s;
  animation-delay: 0s;
}

.ripple-2 {
  top: 60%;
  left: 30%;
  animation-duration: 5s;
  animation-delay: -2s;
}

.ripple-3 {
  top: 20%;
  left: 50%;
  animation-duration: 6s;
  animation-delay: -4s;
}

/* 网格线层 */
.grid-layer {
  position: absolute;
  width: 100%;
  height: 100%;
  opacity: 0.05;
}

.grid-lines {
  width: 100%;
  height: 100%;
  background-image: 
    linear-gradient(rgba(255, 255, 255, 0.1) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.1) 1px, transparent 1px);
  background-size: 60px 60px;
  animation: gridMove 50s infinite linear;
}

/* 动画定义 */
@keyframes backgroundPulse {
  0%, 100% {
    filter: brightness(1) hue-rotate(0deg);
  }
  50% {
    filter: brightness(1.1) hue-rotate(15deg);
  }
}

@keyframes morphingGradient {
  0%, 100% {
    transform: translate(0, 0) scale(1) rotate(0deg);
    opacity: 1;
  }
  25% {
    transform: translate(20px, -20px) scale(1.1) rotate(90deg);
    opacity: 0.8;
  }
  50% {
    transform: translate(-10px, 30px) scale(0.9) rotate(180deg);
    opacity: 0.9;
  }
  75% {
    transform: translate(-30px, -10px) scale(1.05) rotate(270deg);
    opacity: 0.7;
  }
}

@keyframes floatRotate {
  0%, 100% {
    transform: translate(0, 0) rotate(0deg) scale(1);
  }
  25% {
    transform: translate(30px, -40px) rotate(90deg) scale(1.1);
  }
  50% {
    transform: translate(-20px, 50px) rotate(180deg) scale(0.9);
  }
  75% {
    transform: translate(-50px, -20px) rotate(270deg) scale(1.05);
  }
}

@keyframes floatPulse {
  0%, 100% {
    transform: translate(0, 0) scale(1);
    opacity: 0.8;
  }
  50% {
    transform: translate(0, -30px) scale(1.2);
    opacity: 1;
  }
}

@keyframes floatBounce {
  0%, 100% {
    transform: translate(0, 0) scale(1);
  }
  25% {
    transform: translate(15px, -25px) scale(1.05);
  }
  50% {
    transform: translate(-10px, 15px) scale(0.95);
  }
  75% {
    transform: translate(-20px, -10px) scale(1.02);
  }
}

@keyframes floatSway {
  0%, 100% {
    transform: translate(0, 0) rotate(0deg);
  }
  33% {
    transform: translate(25px, -15px) rotate(15deg);
  }
  66% {
    transform: translate(-15px, 25px) rotate(-10deg);
  }
}

@keyframes floatSpin {
  0% {
    transform: translate(0, 0) rotate(0deg);
  }
  100% {
    transform: translate(0, 0) rotate(360deg);
  }
}

@keyframes floatDrift {
  0%, 100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(40px, -40px);
  }
}

@keyframes floatOrbit {
  0% {
    transform: translate(0, 0) rotate(0deg);
  }
  25% {
    transform: translate(30px, 30px) rotate(90deg);
  }
  50% {
    transform: translate(0, 60px) rotate(180deg);
  }
  75% {
    transform: translate(-30px, 30px) rotate(270deg);
  }
  100% {
    transform: translate(0, 0) rotate(360deg);
  }
}

@keyframes starTwinkle {
  0%, 100% {
    opacity: 0.3;
    transform: scale(1);
  }
  50% {
    opacity: 1;
    transform: scale(1.2);
  }
}

@keyframes beamMove {
  0% {
    transform: translateY(-100vh) rotate(var(--rotation, 0deg));
    opacity: 0;
  }
  10% {
    opacity: 1;
  }
  90% {
    opacity: 1;
  }
  100% {
    transform: translateY(100vh) rotate(var(--rotation, 0deg));
    opacity: 0;
  }
}

@keyframes rippleExpand {
  0% {
    width: 0;
    height: 0;
    opacity: 1;
  }
  100% {
    width: 300px;
    height: 300px;
    opacity: 0;
  }
}

@keyframes float {
  0%, 100% {
    transform: translate(0, 0) rotate(0deg) scale(1);
  }
  25% {
    transform: translate(30px, -30px) rotate(90deg) scale(1.05);
  }
  50% {
    transform: translate(-20px, 40px) rotate(180deg) scale(0.95);
  }
  75% {
    transform: translate(-40px, -20px) rotate(270deg) scale(1.02);
  }
}

@keyframes particleFloat {
  0% {
    transform: translateY(100vh) translateX(0) scale(0);
    opacity: 0;
  }
  10% {
    transform: translateY(90vh) translateX(10px) scale(1);
    opacity: 1;
  }
  90% {
    transform: translateY(10vh) translateX(50px) scale(1);
    opacity: 1;
  }
  100% {
    transform: translateY(-10vh) translateX(100px) scale(0);
    opacity: 0;
  }
}

@keyframes gridMove {
  0% {
    transform: translate(0, 0);
  }
  100% {
    transform: translate(60px, 60px);
  }
}

/* 表单容器动画 */
.form-container {
  animation: formSlideIn 1.2s ease-out;
}

.form-content {
  animation: formFadeIn 1.5s ease-out 0.3s both;
}

.logo-container {
  animation: logoFloat 3s ease-in-out infinite, logoGlow 2s ease-in-out infinite alternate;
}

.logo-icon {
  animation: logoSpin 10s linear infinite;
}

.footer-text {
  animation: formFadeIn 1.8s ease-out 0.6s both;
}

@keyframes formSlideIn {
  0% {
    transform: translateY(50px);
    opacity: 0;
  }
  100% {
    transform: translateY(0);
    opacity: 1;
  }
}

@keyframes formFadeIn {
  0% {
    opacity: 0;
    transform: translateY(20px);
  }
  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes logoFloat {
  0%, 100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-10px);
  }
}

@keyframes logoGlow {
  0% {
    box-shadow: 0 15px 35px rgba(0, 0, 0, 0.1), 0 0 20px rgba(59, 130, 246, 0.3);
  }
  100% {
    box-shadow: 0 15px 35px rgba(0, 0, 0, 0.2), 0 0 40px rgba(59, 130, 246, 0.6);
  }
}

@keyframes logoSpin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

/* 响应式调整 */
@media (max-width: 768px) {
  .geometric-shape {
    transform: scale(0.7);
  }
  
  .grid-lines {
    background-size: 40px 40px;
  }
  
  .beam {
    height: 150px;
  }
  
  .ripple {
    max-width: 200px;
    max-height: 200px;
  }
}

/* 增强表单的磨砂玻璃效果 */
.auth-container :deep(.p-card) {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(25px) saturate(180%);
  border: 1px solid rgba(255, 255, 255, 0.25);
  box-shadow: 
    0 25px 45px rgba(0, 0, 0, 0.1),
    0 0 0 1px rgba(255, 255, 255, 0.05) inset;
  border-radius: 20px;
  overflow: hidden;
}

.auth-container :deep(.p-card .p-card-content) {
  background: transparent;
}

.auth-container :deep(.p-card .p-card-header) {
  background: transparent;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

/* 表单文字颜色调整 */
.auth-container :deep(.p-card h1) {
  color: #fff;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.auth-container :deep(.p-card p) {
  color: rgba(255, 255, 255, 0.8);
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

.auth-container :deep(.p-float-label label) {
  color: rgba(255, 255, 255, 0.8);
}

.auth-container :deep(.p-inputtext) {
  background: rgba(255, 255, 255, 0.9);
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: #334155;
}

.auth-container :deep(.p-inputtext:focus) {
  background: rgba(255, 255, 255, 0.95);
  border-color: rgba(59, 130, 246, 0.5);
  box-shadow: 0 0 0 1px rgba(59, 130, 246, 0.3);
}

.auth-container :deep(.p-inputtext::placeholder) {
  color: rgba(100, 116, 139, 0.6);
}

.auth-container :deep(.p-password input) {
  background: rgba(255, 255, 255, 0.9);
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: #334155;
}

.auth-container :deep(.p-password input:focus) {
  background: rgba(255, 255, 255, 0.95);
  border-color: rgba(59, 130, 246, 0.5);
  box-shadow: 0 0 0 1px rgba(59, 130, 246, 0.3);
}

.auth-container :deep(.p-checkbox .p-checkbox-box) {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.3);
}

.auth-container :deep(.p-checkbox .p-checkbox-box.p-highlight) {
  background: rgba(255, 255, 255, 0.9);
  border-color: rgba(255, 255, 255, 0.9);
}

.auth-container :deep(.p-divider .p-divider-content) {
  background: transparent;
}

.auth-container :deep(label[for="remember"]) {
  color: rgba(255, 255, 255, 0.8);
}

.auth-container :deep(a) {
  color: rgba(255, 255, 255, 0.9);
}

.auth-container :deep(span) {
  color: rgba(255, 255, 255, 0.8);
}

/* Footer文字颜色 */
.auth-container .text-surface-500 {
  color: rgba(255, 255, 255, 0.6) !important;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

/* Logo优化 */
.auth-container .bg-primary-500 {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.2) 0%, rgba(255, 255, 255, 0.1) 100%) !important;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: 
    0 15px 35px rgba(0, 0, 0, 0.1),
    0 0 0 1px rgba(255, 255, 255, 0.1) inset;
}
</style>
