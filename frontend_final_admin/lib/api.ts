const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL;

async function apiRequest(endpoint: string, options: RequestInit = {}) {
  const url = `${API_BASE_URL}${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      ...(options.body instanceof FormData ? {} : { 'Content-Type': 'application/json' }),
      ...options.headers,
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('API request error:', errorText);
    throw new Error(`API request failed: ${response.statusText}`);
  }

  return response.json();
}

async function apiFileUpload(endpoint: string, file: File, additionalData?: Record<string, any>) {
  const url = `${API_BASE_URL}${endpoint}`;
  const formData = new FormData();
  formData.append('file', file);

  if (additionalData) {
    Object.entries(additionalData).forEach(([key, value]) => {
      formData.append(key, value);
    });
  }

  const response = await fetch(url, {
    method: 'POST',
    body: formData,
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('File upload error:', errorText);
    throw new Error(`File upload failed: ${response.statusText}`);
  }

  return response.json();
}

// ---------------------------
// 📂 Upload Functions
// ---------------------------

export async function uploadGroups(file: File) {
  return apiFileUpload('/upload-groups/', file);
}

export async function uploadContacts(groupId: string, file: File) {
  return apiFileUpload(`/upload-contacts/${groupId}/`, file);
}

// ---------------------------
// 🔔 Messaging Functions
// ---------------------------

export async function sendMessageToGroupId(groupId: number, content: string, priority = 'low', expiry_days = 7) {
  return apiRequest(`/send-message/${groupId}/?content=${encodeURIComponent(content)}&priority=${priority}&expiry_days=${expiry_days}`, {
    method: 'POST',
  });
}

export async function fetchMessagesByPhoneNumber(phoneNumber: string) {
  return apiRequest(`/messages/${phoneNumber}/`);
}

// ---------------------------
// 📨 Message History & Delete
// ---------------------------

// Returns: [{ id, group, content, priority, expiry, timestamp }]
export async function getMessageHistory() {
  return apiRequest('/messages/history/');
}

export async function deleteMessage(messageId: number) {
  return apiRequest(`/messages/${messageId}/`, {
    method: 'DELETE',
  });
}

// ---------------------------
// 📁 Groups
// ---------------------------

export async function getGroupHierarchy(groupName?: string) {
  const endpoint = groupName
    ? `/groups/hierarchy/?group_name=${encodeURIComponent(groupName)}`
    : '/groups/hierarchy/';
  return apiRequest(endpoint);
}

// ---------------------------
// 📲 Device Registration
// ---------------------------

export async function registerDevice(deviceId: string, phoneNumber: string) {
  return apiRequest(`/register-device/${deviceId}/${phoneNumber}`, {
    method: 'POST',
  });
}

// ---------------------------
// 📊 Dummy Stats (mock)
// ---------------------------

export async function getStats() {
  return apiRequest('/stats/');
}

// ---------------------------
// ⚙️ Example loader
// ---------------------------

const loadHierarchy = async () => {
  setLoading(true);
  try {
    const data = await getGroupHierarchy();
    setGroups(data);
  } catch (error) {
    console.error('Failed to load hierarchy:', error);
  } finally {
    setLoading(false);
  }
};

// Mock state setters
let loading = false;
function setLoading(value: boolean) {
  loading = value;
}

let groups: any = null;
function setGroups(data: any) {
  groups = data;
}

// ---------------------------
// ✏️ Update Message
// ---------------------------

export async function updateMessage(messageId: number, data: { content?: string; priority?: string; expiry?: string }) {
  return apiRequest(`/messages/${messageId}/`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
}
