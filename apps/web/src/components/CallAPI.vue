<script setup lang="ts">
import {onMounted, ref} from "vue"

interface ApiResponse {
  status: string
  message: string
  time: string
}

const data = ref<ApiResponse | null>(null)
const loading = ref<boolean>(false)
const error = ref<string | null>(null)

const fetchApi = async (): Promise<void> => {
  loading.value = true
  error.value = null

  try {
    const response = await fetch("http://localhost:8080/api/test")

    if (!response.ok) {
      throw new Error("API request failed")
    }

    data.value = await response.json()
  } catch (err) {
    error.value = "Không gọi được API"
    console.error(err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchApi()
})
</script>

<template>
  <div class="container">
    <h2>Laravel API Test (Fetch)</h2>

    <button @click="fetchApi">Call API</button>

    <p v-if="loading">Loading...</p>

    <p v-if="error">{{ error }}</p>

    <div v-if="data">
      <p><b>Status:</b> {{ data.status }}</p>
      <p><b>Message:</b> {{ data.message }}</p>
      <p><b>Time:</b> {{ data.time }}</p>
    </div>
  </div>
</template>

<style scoped>
.container {
  padding: 20px;
}

button {
  padding: 8px 14px;
  margin-bottom: 10px;
}
</style>