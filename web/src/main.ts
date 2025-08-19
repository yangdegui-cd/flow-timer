import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import './styles/index.css'
/* these are necessary styles for vue flow */
import '@vue-flow/core/dist/style.css';
/* this contains the default theme, these are optional styles */
import '@vue-flow/core/dist/theme-default.css';
import '@fortawesome/fontawesome-free/css/all.min.css'
import GaIcon from "./components/icon/ga-icon.vue";
//@ts-ignore
import 'virtual:svg-icons-register';
import router from "./router";
import PrimeVue from 'primevue/config';
import ToastService from 'primevue/toastservice';
import Aura from '@primeuix/themes/aura';
import Tooltip from 'primevue/tooltip';
import ConfirmationService from 'primevue/confirmationservice';
import { actionCableService } from './services/actioncable';



const app = createApp(App);
const pinia = createPinia();

app.component('ga-icon', GaIcon)
app.directive('tooltip', Tooltip);
app.use(pinia);
app.use(PrimeVue, {
  theme: {
    preset: Aura,
    options: {
      cssLayer: {
        name: 'primevue',
        order: 'base,tailwind-base, primevue,theme, tailwind-utilities'
      },
    }
  },
  ripple: true,
  size: 'small',
});
app.use(ToastService);
app.use(ConfirmationService);
app.use(router);

// 初始化全局ActionCable连接
actionCableService.initialize();

app.mount('#app');
