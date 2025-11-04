<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Button from 'primevue/button'
import Calendar from 'primevue/calendar'
import InputNumber from 'primevue/inputnumber'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import RadioButton from 'primevue/radiobutton'

interface DateConfig {
  type: 'absolute' | 'relative'
  date: string | number
}

interface TimeRangeConfig {
  start_date: DateConfig
  end_date: DateConfig
}

interface Props {
  modelValue?: TimeRangeConfig | null
}

interface Emits {
  (e: 'update:modelValue', value: TimeRangeConfig): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const visible = ref(false)

// 主要配置 - 保存的数据
const startDateType = ref<'absolute' | 'relative'>('relative')
const startDate = ref<Date>(new Date(new Date().setDate(new Date().getDate() - 30)))
const endDateType = ref<'absolute' | 'relative'>('relative')
const endDate = ref<Date>(new Date(new Date().setDate(new Date().getDate() - 1)))

// 临时配置 - 对话框中编辑的数据
const tempStartType = ref<'absolute' | 'relative'>('relative')
const tempEndType = ref<'absolute' | 'relative'>('relative')
const tempStartDate = ref<Date>(new Date())
const tempEndDate = ref<Date>(new Date())

// 计算相对天数 - 从日期计算天数
const computedStartDays = computed({
  get: () => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const startDay = new Date(tempStartDate.value)
    startDay.setHours(0, 0, 0, 0)
    const diffTime = today.getTime() - startDay.getTime()
    return Math.floor(diffTime / (1000 * 60 * 60 * 24))
  },
  set: (days: number) => {
    const date = new Date()
    date.setDate(date.getDate() - days)
    tempStartDate.value = date
  }
})

const computedEndDays = computed({
  get: () => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const endDay = new Date(tempEndDate.value)
    endDay.setHours(0, 0, 0, 0)
    const diffTime = today.getTime() - endDay.getTime()
    return Math.floor(diffTime / (1000 * 60 * 60 * 24))
  },
  set: (days: number) => {
    const date = new Date()
    date.setDate(date.getDate() - days)
    tempEndDate.value = date
  }
})

// 初始化值 - 从 modelValue 解析出日期和类型
watch(() => props.modelValue, (value) => {
  if (value) {
    // 解析开始时间
    startDateType.value = value.start_date.type
    if (value.start_date.type === 'absolute') {
      startDate.value = new Date(value.start_date.date as string)
    } else {
      const days = Math.abs(value.start_date.date as number)
      const date = new Date()
      date.setDate(date.getDate() - days)
      startDate.value = date
    }

    // 解析结束时间
    endDateType.value = value.end_date.type
    if (value.end_date.type === 'absolute') {
      endDate.value = new Date(value.end_date.date as string)
    } else {
      const days = Math.abs(value.end_date.date as number)
      const date = new Date()
      date.setDate(date.getDate() - days)
      endDate.value = date
    }
  }
}, { immediate: true })

// 打开弹出框 - 复制主数据到临时数据
const openDialog = () => {
  tempStartType.value = startDateType.value
  tempStartDate.value = new Date(startDate.value)
  tempEndType.value = endDateType.value
  tempEndDate.value = new Date(endDate.value)
  visible.value = true
}

// 应用选择 - 保存临时数据到主数据
const applySelection = () => {
  startDateType.value = tempStartType.value
  startDate.value = new Date(tempStartDate.value)
  endDateType.value = tempEndType.value
  endDate.value = new Date(tempEndDate.value)

  emit('update:modelValue', buildConfig())
  visible.value = false
}

// 取消
const cancelSelection = () => {
  visible.value = false
}

// 构建配置 - 根据类型将日期转换为对应格式
const buildConfig = (): TimeRangeConfig => {
  // 计算开始时间
  let startValue: string | number
  if (startDateType.value === 'absolute') {
    startValue = startDate.value.toISOString().split('T')[0]
  } else {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const start = new Date(startDate.value)
    start.setHours(0, 0, 0, 0)
    const diffTime = today.getTime() - start.getTime()
    const days = Math.floor(diffTime / (1000 * 60 * 60 * 24))
    startValue = -Math.abs(days)
  }

  // 计算结束时间
  let endValue: string | number
  if (endDateType.value === 'absolute') {
    endValue = endDate.value.toISOString().split('T')[0]
  } else {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const end = new Date(endDate.value)
    end.setHours(0, 0, 0, 0)
    const diffTime = today.getTime() - end.getTime()
    const days = Math.floor(diffTime / (1000 * 60 * 60 * 24))
    endValue = -Math.abs(days)
  }

  return {
    start_date: {
      type: startDateType.value,
      date: startValue
    },
    end_date: {
      type: endDateType.value,
      date: endValue
    }
  }
}

// 快捷选项
const quickOptions = [
  { label: '昨日', action: () => setQuickRange(-1, -1) },
  { label: '今日', action: () => setQuickRange(0, 0) },
  { label: '上周', action: () => setLastWeek() },
  { label: '本周', action: () => setThisWeek() },
  { label: '上月', action: () => setLastMonth() },
  { label: '本月', action: () => setThisMonth() },
  { label: '过去7天', action: () => setQuickRange(-7, -1) },
  { label: '最近7天', action: () => setQuickRange(-6, 0) },
  { label: '过去30天', action: () => setQuickRange(-30, -1) },
  { label: '最近30天', action: () => setQuickRange(-29, 0) },
  { label: '自某日至昨日', action: () => setCustomToYesterday() },
  { label: '自某日至今', action: () => setCustomToToday() }
]

// 快捷选项函数 - 直接设置日期，时间类型保持不变
function setQuickRange(startDays: number, endDays: number) {
  const start = new Date()
  start.setDate(start.getDate() + startDays)
  const end = new Date()
  end.setDate(end.getDate() + endDays)
  tempStartDate.value = start
  tempEndDate.value = end
}

function setLastWeek() {
  const now = new Date()
  const dayOfWeek = now.getDay()
  const lastWeekEnd = new Date(now)
  lastWeekEnd.setDate(now.getDate() - dayOfWeek)
  const lastWeekStart = new Date(lastWeekEnd)
  lastWeekStart.setDate(lastWeekEnd.getDate() - 6)
  tempStartDate.value = lastWeekStart
  tempEndDate.value = lastWeekEnd
}

function setThisWeek() {
  const now = new Date()
  const dayOfWeek = now.getDay()
  const weekStart = new Date(now)
  weekStart.setDate(now.getDate() - dayOfWeek + 1)
  tempStartDate.value = weekStart
  tempEndDate.value = now
}

function setLastMonth() {
  const now = new Date()
  const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0)
  const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1)
  tempStartDate.value = lastMonthStart
  tempEndDate.value = lastMonthEnd
}

function setThisMonth() {
  const now = new Date()
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
  tempStartDate.value = monthStart
  tempEndDate.value = now
}

function setCustomToYesterday() {
  const yesterday = new Date()
  yesterday.setDate(yesterday.getDate() - 1)
  tempEndDate.value = yesterday
}

function setCustomToToday() {
  tempEndDate.value = new Date()
}

// 计算天数差
function getDaysBetween(date1: Date, date2: Date): number {
  const d1 = new Date(date1)
  d1.setHours(0, 0, 0, 0)
  const d2 = new Date(date2)
  d2.setHours(0, 0, 0, 0)
  const diffTime = d2.getTime() - d1.getTime()
  return Math.floor(diffTime / (1000 * 60 * 60 * 24))
}

// 格式化单个时间的显示
function formatTimeLabel(date: Date, type: 'absolute' | 'relative'): string {
  if (type === 'relative') {
    const today = new Date()
    const between = getDaysBetween(date, today)

    if (between > 1) {
      return "过去" + between + "天"
    } else if (between === 1) {
      return '昨天'
    } else if (between === 0) {
      return '今天'
    } else {
      return "未来" + (between * -1) + "天"
    }
  } else {
    return formatDate(date)
  }
}

// 显示范围 - 主数据的显示
const displayRange = computed(() => {
  const beginStr = formatTimeLabel(startDate.value, startDateType.value)
  const endStr = formatTimeLabel(endDate.value, endDateType.value)

  if (beginStr === endStr && beginStr === '今天') {
    return '今天'
  } else if (beginStr === endStr && beginStr === '昨天') {
    return '昨天'
  } else {
    return beginStr + '~' + endStr
  }
})

// 临时显示范围 - 对话框中编辑数据的显示
const tempDisplayRange = computed(() => {
  const beginStr = formatTimeLabel(tempStartDate.value, tempStartType.value)
  const endStr = formatTimeLabel(tempEndDate.value, tempEndType.value)

  if (beginStr === endStr && beginStr === '今天') {
    return '今天'
  } else if (beginStr === endStr && beginStr === '昨天') {
    return '昨天'
  } else {
    return beginStr + '~' + endStr
  }
})

function formatDate(date: Date): string {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}/${month}/${day}`
}
</script>

<template>
  <div class="date-range-selector">
    <!-- 触发器 -->
    <div class="flex items-center gap-2">
      <InputText
          :value="displayRange"
          readonly
          placeholder="请选择日期范围"
          class="flex-1 cursor-pointer"
          @click="openDialog"
      />
      <Button
          icon="pi pi-calendar"
          @click="openDialog"
          severity="secondary"
          outlined
      />
    </div>

    <!-- 日期范围选择弹出框 -->
    <Dialog
        v-model:visible="visible"
        modal
        header="日期范围"
        :style="{maxWidth: '95vw' }"
        :dismissableMask="true"
        class="date-range-dialog"
    >
      <div class="text-gray-600 mb-4 text-xl">
        {{ tempDisplayRange }}
      </div>

      <div class="date-selector-container">
        <!-- 左侧快捷选项 -->
        <div class="quick-options-panel">
          <Button
              v-for="(option, index) in quickOptions"
              :key="index"
              :label="option.label"
              @click="option.action"
              outlined
              size="small"
              class="quick-btn"
          />
        </div>

        <!-- 右侧日期选择 -->
        <div class="date-selection-panel">
          <div class="time-sections-row">
            <!-- 开始时间 -->
            <div class="time-section">
              <div class="section-title">开始时间</div>

              <div class="input-group">
                <div class="radio-group">
                  <div class="radio-item">
                    <RadioButton
                        v-model="tempStartType"
                        inputId="startRelative"
                        value="relative"
                    />
                    <label for="startRelative" class="radio-label">动态</label>
                  </div>
                  <div class="radio-item">
                    <RadioButton
                        v-model="tempStartType"
                        inputId="startAbsolute"
                        value="absolute"
                    />
                    <label for="startAbsolute" class="radio-label">静态</label>
                  </div>
                </div>

                <div class="value-input-full">
                  <template v-if="tempStartType === 'relative'">
                    <InputGroup class="w-full">
                      <InputNumber v-model="computedStartDays"  :min="0" :max="365" class="w-full" show-buttons/>
                      <InputGroupAddon class="min-w-[70px]">天之前</InputGroupAddon>
                    </InputGroup>
                  </template>
                  <template v-else>
                    <InputText
                        :value="formatDate(tempStartDate)"
                        readonly
                        placeholder="选择开始日期"
                        class="w-full"
                    />
                  </template>
                </div>
              </div>

              <!-- 开始日期日历 -->
              <div class="calendar-container">
                <Calendar
                    v-model="tempStartDate"
                    inline
                />
              </div>
            </div>

            <!-- 结束时间 -->
            <div class="time-section">
              <div class="section-title">结束时间</div>

              <div class="input-group">
                <div class="radio-group">
                  <div class="radio-item">
                    <RadioButton
                        v-model="tempEndType"
                        inputId="endRelative"
                        value="relative"
                    />
                    <label for="endRelative" class="radio-label">动态</label>
                  </div>
                  <div class="radio-item">
                    <RadioButton
                        v-model="tempEndType"
                        inputId="endAbsolute"
                        value="absolute"
                    />
                    <label for="endAbsolute" class="radio-label">静态</label>
                  </div>
                </div>

                <div class="value-input-full">
                  <template v-if="tempEndType === 'relative'">
                    <InputGroup class="w-full">
                      <InputNumber v-model="computedEndDays"  :min="0" :max="365" class="w-full" show-buttons/>
                      <InputGroupAddon class="min-w-[70px]">天之前</InputGroupAddon>
                    </InputGroup>
                  </template>
                  <template v-else>
                    <InputText
                        :value="formatDate(tempEndDate)"
                        readonly
                        placeholder="选择结束日期"
                        class="w-full"
                    />
                  </template>
                </div>
              </div>

              <!-- 结束日期日历 -->
              <div class="calendar-container">
                <Calendar
                    v-model="tempEndDate"
                    inline
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="footer-divider"></div>

      <template #footer>
        <Button
            label="取消"
            icon="pi pi-times"
            @click="cancelSelection"
            text
        />
        <Button
            label="应用"
            icon="pi pi-check"
            @click="applySelection"
        />
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
.cursor-pointer {
  cursor: pointer;
}

.date-selector-container {
  display: block;
  width: 100%;
  overflow: hidden;
  position: relative;
}

.divider-line {
  position: absolute;
  left: 216px;
  top: 0;
  bottom: 0;
  width: 1px;
  background: #e5e7eb;
  z-index: 1;
}

.quick-options-panel {
  width: 200px;
  padding-right: 16px;
  float: left;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  align-content: start;
}

.quick-btn {
  width: 100%;
  justify-content: center;
}

.date-selection-panel {
  width: 640px;
  float: left;
  padding-left:20px;
}

.footer-divider {
  width: 100%;
  height: 1px;
  background: #e5e7eb;
  margin-top: 20px;
}

.time-sections-row {
  display: flex;
  gap: 24px;
}

.time-section {
  flex: 1;
  min-width: 0;
}

.section-title {
  font-size: 13px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #f3f4f6;
}

.input-group {
  margin-bottom: 12px;
}

.radio-group {
  display: flex;
  gap: 16px;
  padding: 6px 12px;
  background: #f9fafb;
  border-radius: 6px;
  border: 1px solid #e5e7eb;
  margin-bottom: 10px;
  width: 295px;
  justify-content: center;
}

.radio-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.radio-label {
  font-size: 13px;
  color: #374151;
  cursor: pointer;
  user-select: none;
}

.value-input-full {
  width: 295px;
}

.calendar-container {
  margin-top: 12px;
  width: 295px;
}

:deep(.p-inputnumber-input) {
  text-align: center;
  font-size: 14px;
}

:deep(.p-datepicker) {
  border: none;
  box-shadow: none;
  width: 100% !important;
}

:deep(.p-datepicker table) {
  width: 100%;
}

:deep(.p-calendar .p-inputtext) {
  text-align: center;
  font-size: 13px;
}

:deep(.p-calendar-w-btn .p-inputtext) {
  padding-right: 2.5rem;
}

:deep(.p-button-label) {
  text-align: center;
}

.w-full {
  width: 100%;
}

:deep(.w-full .p-inputnumber),
:deep(.w-full.p-inputnumber) {
  width: 100%;
}

:deep(.w-full .p-calendar),
:deep(.w-full.p-calendar) {
  width: 100%;
}
</style>
