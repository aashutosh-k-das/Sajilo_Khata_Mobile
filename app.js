import { db } from './db.js';
import { locales } from './locales.js';
import { sparrowSMS } from './sparrow_sms.js';

// Global application state
let currentLanguage = 'ne'; // default to Nepali
let isOnline = true;
let activeCart = [];
let selectedCustomerForDetail = null;

// Initialize App
document.addEventListener('DOMContentLoaded', () => {
  db.init();
  setupTimeSimulation();
  initRouting();
  initLocalization();
  initTheme();
  setupEventListeners();
  applyDialogLightDismissFallback();
  
  // Render based on session
  checkAuthSession();
});

// Simulate status bar clock
function setupTimeSimulation() {
  const timeEl = document.getElementById('simulated-time');
  const updateTime = () => {
    const now = new Date();
    let hrs = now.getHours();
    let mins = now.getMinutes();
    hrs = hrs < 10 ? '0' + hrs : hrs;
    mins = mins < 10 ? '0' + mins : mins;
    timeEl.textContent = `${hrs}:${mins}`;
  };
  updateTime();
  setInterval(updateTime, 60000);
}

// Router & View Manager
function initRouting() {
  const navItems = document.querySelectorAll('.nav-item');
  navItems.forEach(item => {
    item.addEventListener('click', () => {
      const targetPageId = item.getAttribute('data-target');
      navigateToPage(targetPageId);
    });
  });
}

function navigateToPage(pageId) {
  // Hide all pages
  document.querySelectorAll('.page').forEach(page => {
    page.classList.remove('active');
  });

  // Show target page
  const targetPage = document.getElementById(pageId);
  if (targetPage) {
    targetPage.classList.add('active');
  }

  // Update nav item active status
  document.querySelectorAll('.nav-item').forEach(nav => {
    nav.classList.remove('active');
    if (nav.getAttribute('data-target') === pageId) {
      nav.classList.add('active');
    }
  });

  // Re-render modules depending on the active page
  if (pageId === 'page-dashboard') {
    renderDashboard();
  } else if (pageId === 'page-billing') {
    renderBillingScreen();
  } else if (pageId === 'page-inventory') {
    renderInventoryScreen();
  } else if (pageId === 'page-khata') {
    renderKhataScreen();
  }
}

// Check if user is logged in
function checkAuthSession() {
  const session = db.getSession();
  const authSection = document.getElementById('page-auth');
  const appHeader = document.getElementById('app-header');
  const appNav = document.getElementById('app-nav');

  if (session) {
    authSection.classList.remove('active');
    appHeader.style.display = 'flex';
    appNav.style.display = 'flex';
    navigateToPage('page-dashboard');
  } else {
    authSection.classList.add('active');
    appHeader.style.display = 'none';
    appNav.style.display = 'none';
  }
}

// --- Multi-language Translation ---
function initLocalization() {
  updateDOMTranslations();
}

function toggleLanguage() {
  currentLanguage = currentLanguage === 'ne' ? 'en' : 'ne';
  const btn = document.getElementById('toggle-lang');
  btn.textContent = currentLanguage === 'ne' ? '🇳🇵' : '🇺🇸';
  updateDOMTranslations();
  
  // Re-render active screens to apply localization updates
  const activePage = document.querySelector('.page.active');
  if (activePage) {
    navigateToPage(activePage.id);
  }
}

function updateDOMTranslations() {
  const trans = locales[currentLanguage];
  
  // Update elements with data-locale attributes
  document.querySelectorAll('[data-locale]').forEach(el => {
    const key = el.getAttribute('data-locale');
    if (trans[key]) {
      // If it has children and text, check nodes
      if (el.childNodes.length > 0) {
        // Find text node and replace it
        let replaced = false;
        el.childNodes.forEach(child => {
          if (child.nodeType === Node.TEXT_NODE && child.textContent.trim() !== '') {
            child.textContent = trans[key];
            replaced = true;
          }
        });
        if (!replaced) el.textContent = trans[key];
      } else {
        el.textContent = trans[key];
      }
    }
  });

  // Update input placeholders
  document.querySelectorAll('[data-placeholder]').forEach(el => {
    const key = el.getAttribute('data-placeholder');
    if (trans[key]) {
      el.placeholder = trans[key];
    }
  });
}

// --- Theme Management ---
function initTheme() {
  const savedTheme = localStorage.getItem('sajilokhata_theme') || 'light';
  document.documentElement.setAttribute('data-theme', savedTheme);
}

function toggleTheme() {
  const currentTheme = document.documentElement.getAttribute('data-theme');
  const newTheme = currentTheme === 'light' ? 'dark' : 'light';
  document.documentElement.setAttribute('data-theme', newTheme);
  localStorage.setItem('sajilokhata_theme', newTheme);
  showToast(newTheme === 'dark' ? 'Dark Mode active' : 'Light Mode active');
}

// --- Helper Dialog fallbacks for Light Dismiss in older browsers ---
function applyDialogLightDismissFallback() {
  const dialogs = document.querySelectorAll('dialog');
  dialogs.forEach(dialog => {
    if (!('closedBy' in HTMLDialogElement.prototype)) {
      dialog.addEventListener('click', (event) => {
        if (event.target !== dialog) return;
        const rect = dialog.getBoundingClientRect();
        const isInside = (
          rect.top <= event.clientY &&
          event.clientY <= rect.top + rect.height &&
          rect.left <= event.clientX &&
          event.clientX <= rect.left + rect.width
        );
        if (!isInside) {
          dialog.close();
        }
      });
    }
  });
}

// --- Event Listeners Setup ---
function setupEventListeners() {
  // Language & Theme Toggle
  document.getElementById('toggle-lang').addEventListener('click', toggleLanguage);
  document.getElementById('toggle-theme').addEventListener('click', toggleTheme);
  
  // Logout
  document.getElementById('logout-btn').addEventListener('click', () => {
    db.clearSession();
    checkAuthSession();
    showToast('Logged out successfully');
  });

  // Auth OTP flow
  document.getElementById('auth-phone-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const phone = document.getElementById('auth-phone').value;
    const mockInfoEl = document.getElementById('otp-mock-info');
    
    // Set instructions context for Nepal OTP verification
    const trans = locales[currentLanguage];
    mockInfoEl.textContent = trans.mockOtpSent;
    
    document.getElementById('dialog-otp').showModal();
  });

  document.getElementById('otp-verify-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const phone = document.getElementById('auth-phone').value;
    const otp = document.getElementById('otp-input').value;
    
    if (otp === '123456') {
      db.setSession(phone);
      document.getElementById('dialog-otp').close();
      checkAuthSession();
      showToast(currentLanguage === 'ne' ? 'लगइन सफल भयो' : 'Logged in successfully');
    } else {
      showToast(currentLanguage === 'ne' ? 'गलत OTP कोड' : 'Invalid OTP code', true);
    }
  });

  // Quick Action triggers
  document.getElementById('action-new-sale').addEventListener('click', () => navigateToPage('page-billing'));
  document.getElementById('action-new-product').addEventListener('click', () => {
    document.getElementById('add-product-form').reset();
    document.getElementById('dialog-add-product').showModal();
  });
  document.getElementById('action-new-customer').addEventListener('click', () => {
    document.getElementById('add-customer-form').reset();
    document.getElementById('dialog-add-customer').showModal();
  });

  // Inline Quick Add Customer on billing screen
  document.getElementById('btn-quick-add-customer').addEventListener('click', () => {
    document.getElementById('add-customer-form').reset();
    document.getElementById('dialog-add-customer').showModal();
  });

  // Trigger Add dialogs from lists
  document.getElementById('btn-inventory-add-product').addEventListener('click', () => {
    document.getElementById('add-product-form').reset();
    document.getElementById('dialog-add-product').showModal();
  });
  document.getElementById('btn-khata-add-customer').addEventListener('click', () => {
    document.getElementById('add-customer-form').reset();
    document.getElementById('dialog-add-customer').showModal();
  });

  // Forms submit listeners
  document.getElementById('add-customer-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const name = document.getElementById('cust-name-input').value;
    const phone = document.getElementById('cust-phone-input').value;
    
    db.saveCustomer({ name, phone });
    document.getElementById('dialog-add-customer').close();
    showToast(currentLanguage === 'ne' ? 'ग्राहक थपियो' : 'Customer added');
    
    // Refresh screens
    const activePage = document.querySelector('.page.active');
    navigateToPage(activePage.id);
  });

  document.getElementById('add-product-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const name = document.getElementById('prod-name-input').value;
    const category = document.getElementById('prod-category-input').value;
    const stockQty = parseInt(document.getElementById('prod-qty-input').value);
    const buyingPrice = parseFloat(document.getElementById('prod-buying-input').value);
    const sellingPrice = parseFloat(document.getElementById('prod-selling-input').value);
    const minThreshold = parseInt(document.getElementById('prod-threshold-input').value);

    db.saveProduct({ name, category, stockQty, buyingPrice, sellingPrice, minThreshold });
    document.getElementById('dialog-add-product').close();
    showToast(currentLanguage === 'ne' ? 'सामान सुरक्षित भयो' : 'Product saved');
    
    const activePage = document.querySelector('.page.active');
    navigateToPage(activePage.id);
  });

  // Search logic
  document.getElementById('inventory-search').addEventListener('input', (e) => {
    renderInventoryScreen(e.target.value);
  });

  document.getElementById('khata-search').addEventListener('input', (e) => {
    renderKhataScreen(e.target.value);
  });

  // Stock update adjustment form
  document.getElementById('adjust-stock-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const pId = document.getElementById('adjust-product-id').value;
    const qty = parseInt(document.getElementById('adjust-qty-input').value);

    db.updateProductStock(pId, qty);
    document.getElementById('dialog-adjust-stock').close();
    showToast(currentLanguage === 'ne' ? 'मौज्दात अपडेट भयो' : 'Stock updated');
    renderInventoryScreen();
  });

  // Billing add item to cart
  document.getElementById('btn-add-to-cart').addEventListener('click', () => {
    const prodSelect = document.getElementById('bill-product-select');
    const qtyInput = document.getElementById('bill-qty-input');
    const priceInput = document.getElementById('bill-price-input');

    const prodName = prodSelect.value;
    const qty = parseInt(qtyInput.value);
    const price = parseFloat(priceInput.value);

    if (!prodName) {
      showToast(currentLanguage === 'ne' ? 'कृपया सामान छान्नुहोस्' : 'Please select a product', true);
      return;
    }
    if (qty <= 0 || isNaN(price) || price <= 0) {
      showToast(currentLanguage === 'ne' ? 'मात्रा वा दर मिलेन' : 'Invalid quantity or price', true);
      return;
    }

    // Add to cart array
    const existing = activeCart.find(item => item.name === prodName);
    if (existing) {
      existing.qty += qty;
    } else {
      activeCart.push({ name: prodName, qty, price });
    }

    // Reset select inputs
    prodSelect.value = '';
    qtyInput.value = '1';
    priceInput.value = '';

    renderCart();
  });

  // Handle bill checkout submit
  document.getElementById('billing-form').addEventListener('submit', (e) => {
    e.preventDefault();
    if (activeCart.length === 0) {
      showToast(currentLanguage === 'ne' ? 'बिल खाली छ, सामान थप्नुहोस्' : 'Cart is empty, please add items', true);
      return;
    }

    const customerSelect = document.getElementById('bill-customer-select');
    const customerId = customerSelect.value;
    let customerName = locales[currentLanguage].anonymousCustomer;
    
    if (customerId) {
      const cust = db.getCustomers().find(c => c.id === customerId);
      if (cust) customerName = cust.name;
    }

    const payMethod = document.querySelector('input[name="payment-method"]:checked').value;
    
    // Prevent credit selection if customer is anonymous
    if (payMethod === 'credit' && !customerId) {
      showToast(currentLanguage === 'ne' ? 'उधारोको लागि ग्राहक छान्न आवश्यक छ' : 'Please select a customer for credit sales', true);
      return;
    }

    // Subtotal calculations
    const subtotal = activeCart.reduce((sum, item) => sum + (item.qty * item.price), 0);
    const vat = subtotal * 0.13; // 13% standard VAT in Nepal
    const total = subtotal + vat;

    const newBill = db.saveBill({
      customerId,
      customerName,
      items: activeCart,
      subtotal,
      vat,
      total,
      paymentMethod: payMethod
    });

    // Clear cart
    activeCart = [];
    renderCart();
    
    // If online pay chosen, display QR, otherwise show receipt
    if (payMethod === 'online') {
      document.getElementById('dialog-online-qr').showModal();
    } else {
      showInvoiceReceipt(newBill);
    }
    
    showToast(currentLanguage === 'ne' ? 'बिल सुरक्षित भयो' : 'Bill saved');
  });

  // Ledger Add Transaction triggers
  document.getElementById('btn-ledger-give-credit').addEventListener('click', () => {
    openLedgerTransactionForm('credit');
  });
  document.getElementById('btn-ledger-receive-pay').addEventListener('click', () => {
    openLedgerTransactionForm('payment');
  });

  document.getElementById('ledger-transaction-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const type = document.getElementById('ledger-tx-type').value;
    const amount = parseFloat(document.getElementById('ledger-amount-input').value);
    const desc = document.getElementById('ledger-desc-input').value || 
                 (type === 'credit' ? 'Credit given' : 'Payment received');

    if (selectedCustomerForDetail) {
      db.addTransaction(selectedCustomerForDetail.id, type, amount, desc);
      document.getElementById('dialog-ledger-transaction').close();
      
      // Reload customer details and background khata list
      showCustomerDetails(selectedCustomerForDetail.id);
      renderKhataScreen();
      showToast(currentLanguage === 'ne' ? 'खाता रेकर्ड अपडेट भयो' : 'Khata entry updated');
    }
  });

  // SMS Reminder preview & send triggers
  document.getElementById('btn-send-sms-reminder').addEventListener('click', () => {
    if (selectedCustomerForDetail) {
      const amount = selectedCustomerForDetail.balance;
      if (amount <= 0) {
        showToast(currentLanguage === 'ne' ? 'ग्राहकको कुनै बाँकी रकम छैन' : 'Customer has no outstanding balance', true);
        return;
      }
      
      const shopName = currentLanguage === 'ne' ? 'हाम्रो किराना पसल' : 'Our Kirana Store';
      const text = sparrowSMS.generateReminderText(selectedCustomerForDetail.name, amount, shopName, currentLanguage);
      
      document.getElementById('sms-text-box').textContent = text;
      document.getElementById('dialog-sms-preview').showModal();
    }
  });

  document.getElementById('btn-sms-confirm-send').addEventListener('click', async () => {
    if (selectedCustomerForDetail) {
      const amount = selectedCustomerForDetail.balance;
      const shopName = currentLanguage === 'ne' ? 'हाम्रो किराना पसल' : 'Our Kirana Store';
      const text = sparrowSMS.generateReminderText(selectedCustomerForDetail.name, amount, shopName, currentLanguage);
      
      document.getElementById('dialog-sms-preview').close();
      showToast(currentLanguage === 'ne' ? 'SMS ताकेता पठाउँदै...' : 'Sending SMS reminder...');

      const response = await sparrowSMS.sendSMS(selectedCustomerForDetail.phone, text);
      if (response.status === 'success') {
        showToast(locales[currentLanguage].reminderSent);
      } else {
        showToast('Sparrow SMS API Failed: ' + response.message, true);
      }
    }
  });

  // Product Selection auto fills price
  document.getElementById('bill-product-select').addEventListener('change', (e) => {
    const pName = e.target.value;
    const priceInput = document.getElementById('bill-price-input');
    if (pName) {
      const prod = db.getProducts().find(p => p.name === pName);
      if (prod) {
        priceInput.value = prod.sellingPrice;
      }
    } else {
      priceInput.value = '';
    }
  });

  // --- DEV CONTROLS EVENT HANDLERS ---
  const netBtn = document.getElementById('dev-btn-network');
  const syncBtn = document.getElementById('dev-btn-sync');
  const resetBtn = document.getElementById('dev-btn-reset');

  netBtn.addEventListener('click', () => {
    isOnline = !isOnline;
    const syncDot = document.querySelector('.indicator-dot');
    const syncText = document.getElementById('sync-text');
    
    if (isOnline) {
      syncDot.classList.remove('offline');
      syncText.textContent = currentLanguage === 'ne' ? 'अनलाइन' : 'Online';
      netBtn.textContent = 'Toggle Offline';
      netBtn.style.backgroundColor = '#334155';
      showToast('Connection restored. Firestore ready.');
      // Auto Sync if queue exists
      triggerBackgroundSync();
    } else {
      syncDot.classList.add('offline');
      syncText.textContent = currentLanguage === 'ne' ? 'अफलाइन' : 'Offline';
      netBtn.textContent = 'Toggle Online';
      netBtn.style.backgroundColor = 'var(--danger-color)';
      showToast('Offline mode. Data saves locally.', true);
    }
  });

  syncBtn.addEventListener('click', triggerBackgroundSync);

  resetBtn.addEventListener('click', () => {
    if (confirm('Are you sure you want to reset all data?')) {
      db.resetData();
      showToast('Database reset to defaults');
      navigateToPage('page-dashboard');
    }
  });

  // Low stock card trigger to jump to inventory view
  document.getElementById('card-low-stock-trigger').addEventListener('click', () => {
    navigateToPage('page-inventory');
    // Set search box to identify low stock products
    const lowStockProds = db.getProducts().filter(p => p.stockQty <= p.minThreshold);
    if (lowStockProds.length > 0) {
      document.getElementById('inventory-search').value = ''; // clean search
      renderInventoryScreen();
    }
  });
}

// Simulated sync animation
async function triggerBackgroundSync() {
  if (!isOnline) {
    showToast('Cannot sync in offline mode', true);
    return;
  }
  const syncQueue = db.getSyncQueue();
  if (syncQueue.length === 0) {
    showToast('All local SQLite transactions synced with Cloud Firestore');
    return;
  }

  showToast(locales[currentLanguage].connecting);
  const syncText = document.getElementById('sync-text');
  syncText.textContent = locales[currentLanguage].connecting;

  await db.processSyncQueue((current, total, item) => {
    console.log(`Syncing local write to Cloud: [${item.collection}]`, item.data);
  });

  syncText.textContent = locales[currentLanguage].onlineSync;
  showToast(currentLanguage === 'ne' ? 'क्लाउड सिङ्क सफल भयो' : 'Sync with Firebase completed');
  setTimeout(() => {
    if (isOnline) syncText.textContent = currentLanguage === 'ne' ? 'अनलाइन' : 'Online';
  }, 2000);

  // Refresh dashboard metrics
  renderDashboard();
}

// --- Dynamic Render Functions ---

// 1. Dashboard View
function renderDashboard() {
  const metrics = db.getMetrics();
  const txs = db.getTransactions().slice(0, 5); // get top 5 recent ones

  // Set values
  document.getElementById('metric-sales').textContent = `रु. ${metrics.todaySales.toLocaleString()}`;
  document.getElementById('metric-credit').textContent = `रु. ${metrics.totalCredit.toLocaleString()}`;
  document.getElementById('metric-low-stock').textContent = metrics.lowStockCount;
  document.getElementById('metric-customers').textContent = metrics.activeCustomers;

  // Toggle low stock alert animations
  const lowCard = document.getElementById('card-low-stock-trigger');
  const lowAlertIcon = document.getElementById('low-stock-alert-icon');
  if (metrics.lowStockCount > 0) {
    lowCard.style.border = '2px solid var(--danger-color)';
    lowAlertIcon.style.animation = 'pulse 1s infinite alternate';
  } else {
    lowCard.style.border = '1px solid var(--border-color)';
    lowAlertIcon.style.animation = 'none';
  }

  // Populate list
  const recentList = document.getElementById('dashboard-recent-list');
  recentList.innerHTML = '';

  if (txs.length === 0) {
    recentList.innerHTML = `<div style="text-align: center; font-size: 12px; color: var(--text-secondary); padding: 12px;">No transactions yet.</div>`;
    return;
  }

  const customers = db.getCustomers();

  txs.forEach(tx => {
    const cust = customers.find(c => c.id === tx.customerId);
    const custName = cust ? cust.name : 'Unknown';
    const isCredit = tx.type === 'credit';
    const dateFormatted = new Date(tx.date).toLocaleDateString();

    const row = document.createElement('div');
    row.className = 'list-item';
    row.addEventListener('click', () => {
      if (cust) {
        navigateToPage('page-khata');
        showCustomerDetails(cust.id);
      }
    });

    row.innerHTML = `
      <div class="item-left">
        <span class="item-title">${custName}</span>
        <span class="item-subtitle">${dateFormatted} • ${tx.description}</span>
      </div>
      <div class="item-right ${isCredit ? 'credit-owe' : 'credit-clear'}">
        ${isCredit ? '+' : '-'} रु. ${tx.amount.toLocaleString()}
      </div>
    `;
    recentList.appendChild(row);
  });
}

// 2. Billing View
function renderBillingScreen() {
  // Clear select dropdowns and cart
  const custSelect = document.getElementById('bill-customer-select');
  const prodSelect = document.getElementById('bill-product-select');

  custSelect.innerHTML = `<option value="">${locales[currentLanguage].anonymousCustomer}</option>`;
  prodSelect.innerHTML = `<option value="">-- ${locales[currentLanguage].selectItem} --</option>`;

  // Load Customers
  db.getCustomers().forEach(c => {
    const opt = document.createElement('option');
    opt.value = c.id;
    opt.textContent = `${c.name} (${c.phone})`;
    custSelect.appendChild(opt);
  });

  // Load Products (in stock)
  db.getProducts().forEach(p => {
    const opt = document.createElement('option');
    opt.value = p.name;
    opt.textContent = `${p.name} (Qty: ${p.stockQty})`;
    prodSelect.appendChild(opt);
  });

  renderCart();
}

function renderCart() {
  const cartBody = document.getElementById('cart-table-body');
  cartBody.innerHTML = '';

  if (activeCart.length === 0) {
    cartBody.innerHTML = `<tr><td colspan="4" style="text-align: center; color: var(--text-secondary);">No items added.</td></tr>`;
    updateCartTotals(0, 0, 0);
    return;
  }

  activeCart.forEach((item, index) => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${item.name}</td>
      <td>${item.qty}</td>
      <td>रु. ${item.price}</td>
      <td><button type="button" class="btn-icon" style="width: 24px; height: 24px; padding:0; background: none;" onclick="window.removeItemFromCart(${index})">❌</button></td>
    `;
    cartBody.appendChild(tr);
  });

  // Update Calculations
  const subtotal = activeCart.reduce((sum, item) => sum + (item.qty * item.price), 0);
  const vat = subtotal * 0.13;
  const total = subtotal + vat;

  updateCartTotals(subtotal, vat, total);
}

// Attach cart remove helper to window object for button onclick access
window.removeItemFromCart = function(index) {
  activeCart.splice(index, 1);
  renderCart();
};

function updateCartTotals(sub, vt, tot) {
  document.getElementById('bill-subtotal').textContent = `रु. ${sub.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}`;
  document.getElementById('bill-vat').textContent = `रु. ${vt.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}`;
  document.getElementById('bill-total').textContent = `रु. ${tot.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}`;
}

// 3. Inventory View
function renderInventoryScreen(searchQuery = '') {
  const list = document.getElementById('inventory-list');
  list.innerHTML = '';

  const products = db.getProducts().filter(p => {
    return p.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
           p.category.toLowerCase().includes(searchQuery.toLowerCase());
  });

  if (products.length === 0) {
    list.innerHTML = `<div style="text-align: center; color: var(--text-secondary); padding: 24px;">No products found.</div>`;
    return;
  }

  products.forEach(p => {
    const isLowStock = p.stockQty <= p.minThreshold;
    const isOutOfStock = p.stockQty === 0;
    
    let statusClass = 'badge-success';
    let statusText = locales[currentLanguage].inStock;

    if (isOutOfStock) {
      statusClass = 'badge-danger';
      statusText = locales[currentLanguage].outOfStock;
    } else if (isLowStock) {
      statusClass = 'badge-warning';
      statusText = locales[currentLanguage].lowStock;
    }

    const row = document.createElement('div');
    row.className = 'list-item';
    row.style.borderLeft = isLowStock ? '4px solid var(--danger-color)' : '1px solid var(--border-color)';
    
    row.addEventListener('click', () => {
      openStockAdjustment(p.id);
    });

    row.innerHTML = `
      <div class="item-left">
        <span class="item-title">${p.name}</span>
        <span class="item-subtitle">${p.category} • Selling: रु. ${p.sellingPrice} • Min Alert limit: ${p.minThreshold}</span>
      </div>
      <div class="item-right" style="display: flex; flex-direction: column; align-items: flex-end; gap: 4px;">
        <span>Qty: ${p.stockQty}</span>
        <span class="badge-status ${statusClass}">${statusText}</span>
      </div>
    `;
    list.appendChild(row);
  });
}

function openStockAdjustment(productId) {
  const p = db.getProducts().find(item => item.id === productId);
  if (p) {
    document.getElementById('adjust-product-id').value = p.id;
    document.getElementById('adjust-product-name').textContent = p.name;
    document.getElementById('adjust-qty-input').value = p.stockQty;
    document.getElementById('dialog-adjust-stock').showModal();
  }
}

// 4. Khata View
function renderKhataScreen(searchQuery = '') {
  const list = document.getElementById('khata-list');
  list.innerHTML = '';

  const customers = db.getCustomers().filter(c => {
    return c.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
           c.phone.includes(searchQuery);
  });

  if (customers.length === 0) {
    list.innerHTML = `<div style="text-align: center; color: var(--text-secondary); padding: 24px;">No customers found.</div>`;
    return;
  }

  customers.forEach(c => {
    const oweClass = c.balance > 0 ? 'credit-owe' : 'credit-clear';
    const balanceText = c.balance > 0 ? 
      `${locales[currentLanguage].mustPay}: रु. ${c.balance.toLocaleString()}` : 
      locales[currentLanguage].noDues;

    const row = document.createElement('div');
    row.className = 'list-item';
    row.addEventListener('click', () => {
      showCustomerDetails(c.id);
    });

    row.innerHTML = `
      <div class="item-left">
        <span class="item-title">${c.name}</span>
        <span class="item-subtitle">📞 ${c.phone}</span>
      </div>
      <div class="item-right ${oweClass}">
        ${balanceText}
      </div>
    `;
    list.appendChild(row);
  });
}

function showCustomerDetails(customerId) {
  const customer = db.getCustomers().find(c => c.id === customerId);
  if (!customer) return;

  selectedCustomerForDetail = customer;

  // Title & Info
  document.getElementById('custDetailTitle').textContent = customer.name;
  document.getElementById('detail-customer-balance').textContent = `रु. ${customer.balance.toLocaleString()}`;
  
  // Balance styling
  const balValEl = document.getElementById('detail-customer-balance');
  if (customer.balance > 0) {
    balValEl.style.color = 'var(--danger-color)';
    document.getElementById('btn-send-sms-reminder').style.display = 'block';
  } else {
    balValEl.style.color = 'var(--primary-color)';
    document.getElementById('btn-send-sms-reminder').style.display = 'none';
  }

  // Populate Ledger Transactions List
  const timeline = document.getElementById('detail-ledger-timeline');
  timeline.innerHTML = '';

  const txs = db.getTransactions(customerId);
  if (txs.length === 0) {
    timeline.innerHTML = `<div style="padding:16px; font-size: 11px; text-align:center; color: var(--text-secondary);">No ledger records yet.</div>`;
  } else {
    txs.forEach(tx => {
      const isCredit = tx.type === 'credit';
      const dateStr = new Date(tx.date).toLocaleDateString();
      const div = document.createElement('div');
      div.style.padding = '8px 12px';
      div.style.borderBottom = '1px solid var(--border-color)';
      div.style.display = 'flex';
      div.style.justifyContent = 'space-between';
      div.style.fontSize = '12px';
      
      div.innerHTML = `
        <div>
          <span style="font-weight: 600; color: ${isCredit ? 'var(--danger-color)' : 'var(--success-color)'};">
            ${isCredit ? 'उधारो (Credit)' : 'भुक्तानी (Payment)'}
          </span>
          <span style="font-size: 10px; color: var(--text-secondary); margin-left: 6px;">${dateStr}</span>
          <div style="font-size: 11px; color: var(--text-secondary); margin-top: 2px;">${tx.description}</div>
        </div>
        <strong style="align-self: center;">रु. ${tx.amount.toLocaleString()}</strong>
      `;
      timeline.appendChild(div);
    });
  }

  document.getElementById('dialog-customer-detail').showModal();
}

function openLedgerTransactionForm(type) {
  document.getElementById('ledger-tx-type').value = type;
  document.getElementById('ledger-amount-input').value = '';
  document.getElementById('ledger-desc-input').value = '';
  
  const titleEl = document.getElementById('ledgerTxTitle');
  if (type === 'credit') {
    titleEl.textContent = locales[currentLanguage].giveCredit;
  } else {
    titleEl.textContent = locales[currentLanguage].receivePayment;
  }

  // Close parent detail modal, then show sub-modal
  document.getElementById('dialog-customer-detail').close();
  document.getElementById('dialog-ledger-transaction').showModal();
}

// Invoice print + share layout builder
function showInvoiceReceipt(bill) {
  const content = document.getElementById('receipt-content');
  
  // Format items printout
  const itemsText = bill.items.map(i => {
    const namePad = i.name.padEnd(20).substring(0, 20);
    const qtyPrice = `${i.qty}x${i.price}`.padStart(12);
    return `${namePad}${qtyPrice}`;
  }).join('\n');

  content.innerHTML = `
<div style="text-align: center; font-weight: bold; font-size: 14px;">SAJILO KHATA SHOP</div>
<div style="text-align: center; font-size: 10px;">Birgunj-8, Parsa, Nepal</div>
<div style="margin: 8px 0; border-top: 1px dashed #000;"></div>
<div>Invoice: ${bill.id.substring(0, 8).toUpperCase()}</div>
<div>Date: ${new Date(bill.date).toLocaleString()}</div>
<div>Customer: ${bill.customerName}</div>
<div style="margin: 8px 0; border-top: 1px dashed #000;"></div>
<div style="font-weight: bold;">ITEMS:</div>
<pre style="margin: 0; white-space: pre-wrap; font-family: monospace;">${itemsText}</pre>
<div style="margin: 8px 0; border-top: 1px dashed #000;"></div>
<div style="display:flex; justify-content:space-between;">Subtotal: <span>Rs. ${bill.subtotal.toFixed(2)}</span></div>
<div style="display:flex; justify-content:space-between;">13% VAT: <span>Rs. ${bill.vat.toFixed(2)}</span></div>
<div style="display:flex; justify-content:space-between; font-weight:bold;">Total: <span>Rs. ${bill.total.toFixed(2)}</span></div>
<div style="margin: 8px 0; border-top: 1px dashed #000;"></div>
<div style="text-align: center; font-style: italic;">Thank you for your business!</div>
  `;

  // Attach share event actions
  const wppBtn = document.getElementById('btn-invoice-whatsapp');
  wppBtn.onclick = () => {
    const textMsg = `Invoice from Sajilo Khata\nTotal Amount: Rs. ${bill.total.toFixed(2)}\nItems:\n` + 
                    bill.items.map(i => `- ${i.name} (Qty: ${i.qty})`).join('\n');
    const encoded = encodeURIComponent(textMsg);
    window.open(`https://wa.me/?text=${encoded}`, '_blank');
  };

  const printBtn = document.getElementById('btn-invoice-print');
  printBtn.onclick = () => {
    window.print();
  };

  document.getElementById('dialog-invoice-receipt').showModal();
}

// Toast Messages Alert popup
function showToast(message, isError = false) {
  const toast = document.getElementById('toast-message');
  toast.textContent = message;
  toast.className = 'toast show';
  
  if (isError) {
    toast.style.backgroundColor = 'var(--danger-color)';
  } else {
    toast.style.backgroundColor = 'var(--text-primary)';
  }
  
  setTimeout(() => {
    toast.className = 'toast';
  }, 2500);
}

// Add standard pulses
const styleSheet = document.createElement("style");
styleSheet.innerText = `
  @keyframes pulse {
    0% { transform: scale(1); opacity: 0.8; }
    100% { transform: scale(1.2); opacity: 1; }
  }
`;
document.head.appendChild(styleSheet);
