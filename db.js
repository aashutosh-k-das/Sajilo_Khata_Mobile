// Database helper utilizing localStorage for reliable offline-first persistence
// Simulates SQLite and Firebase Sync behaviour locally

const DB_KEYS = {
  PRODUCTS: "sajilokhata_products",
  CUSTOMERS: "sajilokhata_customers",
  TRANSACTIONS: "sajilokhata_transactions",
  BILLS: "sajilokhata_bills",
  SYNC_QUEUE: "sajilokhata_sync_queue",
  SESSION: "sajilokhata_session",
  LOANS: "sajilokhata_loans"
};

// Initial Nepalese shop seed data
const SEED_PRODUCTS = [
  { id: "p1", name: "Jira Masino Chamal (25kg)", category: "Groceries", stockQty: 12, buyingPrice: 2100, sellingPrice: 2450, minThreshold: 3 },
  { id: "p2", name: "DDC Ghee (1 Litre)", category: "Dairy", stockQty: 5, buyingPrice: 1050, sellingPrice: 1200, minThreshold: 5 },
  { id: "p3", name: "Tokla Chiya (500g)", category: "Tea & Sugar", stockQty: 18, buyingPrice: 180, sellingPrice: 220, minThreshold: 4 },
  { id: "p4", name: "Sugar / Sakhar (1kg)", category: "Tea & Sugar", stockQty: 45, buyingPrice: 85, sellingPrice: 98, minThreshold: 10 },
  { id: "p5", name: "Aashirvaad Atta (5kg)", category: "Groceries", stockQty: 2, buyingPrice: 480, sellingPrice: 540, minThreshold: 5 },
  { id: "p6", name: "Wai Wai Noodles (1 Case)", category: "Snacks", stockQty: 0, buyingPrice: 650, sellingPrice: 720, minThreshold: 2 }
];

const SEED_CUSTOMERS = [
  { id: "c1", name: "Ramesh Parsa", phone: "9855012345", balance: 4500 }, // Pos balance = credit owed to store
  { id: "c2", name: "Sita Devi Sah", phone: "9845098765", balance: 1200 },
  { id: "c3", name: "Birgunj Kirana Supplier", phone: "9804011223", balance: 0 },
  { id: "c4", name: "Hari Prasad Acharya", phone: "9812345678", balance: -500 } // Neg balance = store owes customer
];

const SEED_TRANSACTIONS = [
  { id: "t1", customerId: "c1", type: "credit", amount: 3500, description: "Basmati rice & oil groceries", date: new Date(Date.now() - 86400000 * 3).toISOString() },
  { id: "t2", customerId: "c1", type: "credit", amount: 1000, description: "Sugar and tea", date: new Date(Date.now() - 86400000 * 2).toISOString() },
  { id: "t3", customerId: "c2", type: "credit", amount: 2000, description: "DDC Ghee bottle", date: new Date(Date.now() - 86400000 * 1).toISOString() },
  { id: "t4", customerId: "c2", type: "payment", amount: 800, description: "Partial payment via cash", date: new Date(Date.now() - 3600000 * 4).toISOString() }
];

const SEED_BILLS = [
  { id: "b1", customerId: "c1", customerName: "Ramesh Parsa", items: [{ name: "Jira Masino Chamal (25kg)", qty: 1, price: 2450 }, { name: "Tokla Chiya (500g)", qty: 1, price: 220 }], subtotal: 2670, vat: 347.1, total: 3017.1, date: new Date(Date.now() - 86400000 * 3).toISOString(), paymentMethod: "credit" }
];

// Loan status: 'active' | 'repaid' | 'overdue'
// direction: 'lent' (you gave loan) | 'borrowed' (you received loan)
const SEED_LOANS = [
  {
    id: "l1",
    shopkeeperName: "Mohan Sah Kirana",
    shopkeeperPhone: "9855011122",
    direction: "lent",          // we gave this shopkeeper a loan
    principalAmount: 10000,
    interestRate: 5,            // % per annum (low rate between friends/shops)
    startDate: new Date(Date.now() - 86400000 * 60).toISOString(), // 2 months ago
    dueDate: new Date(Date.now() + 86400000 * 30).toISOString(),
    status: "active",
    repayments: [
      { id: "r1", amount: 3000, date: new Date(Date.now() - 86400000 * 30).toISOString(), note: "Partial repayment" }
    ],
    note: "Emergency stock purchase loan"
  },
  {
    id: "l2",
    shopkeeperName: "Laxmi General Store",
    shopkeeperPhone: "9804012233",
    direction: "borrowed",       // we borrowed from this shopkeeper
    principalAmount: 5000,
    interestRate: 4,
    startDate: new Date(Date.now() - 86400000 * 15).toISOString(),
    dueDate: new Date(Date.now() + 86400000 * 15).toISOString(),
    status: "active",
    repayments: [],
    note: "Temporary cash flow support"
  }
];

export const db = {
  init() {
    if (!localStorage.getItem(DB_KEYS.PRODUCTS)) {
      localStorage.setItem(DB_KEYS.PRODUCTS, JSON.stringify(SEED_PRODUCTS));
    }
    if (!localStorage.getItem(DB_KEYS.CUSTOMERS)) {
      localStorage.setItem(DB_KEYS.CUSTOMERS, JSON.stringify(SEED_CUSTOMERS));
    }
    if (!localStorage.getItem(DB_KEYS.TRANSACTIONS)) {
      localStorage.setItem(DB_KEYS.TRANSACTIONS, JSON.stringify(SEED_TRANSACTIONS));
    }
    if (!localStorage.getItem(DB_KEYS.BILLS)) {
      localStorage.setItem(DB_KEYS.BILLS, JSON.stringify(SEED_BILLS));
    }
    if (!localStorage.getItem(DB_KEYS.SYNC_QUEUE)) {
      localStorage.setItem(DB_KEYS.SYNC_QUEUE, JSON.stringify([]));
    }
    if (!localStorage.getItem(DB_KEYS.LOANS)) {
      localStorage.setItem(DB_KEYS.LOANS, JSON.stringify(SEED_LOANS));
    }
  },

  // --- Auth Session ---
  getSession() {
    const data = localStorage.getItem(DB_KEYS.SESSION);
    return data ? JSON.parse(data) : null;
  },

  setSession(phone) {
    const session = { phone, loggedInAt: new Date().toISOString() };
    localStorage.setItem(DB_KEYS.SESSION, JSON.stringify(session));
    return session;
  },

  clearSession() {
    localStorage.removeItem(DB_KEYS.SESSION);
  },

  // --- Products (Inventory) ---
  getProducts() {
    return JSON.parse(localStorage.getItem(DB_KEYS.PRODUCTS)) || [];
  },

  saveProduct(product) {
    const products = this.getProducts();
    if (product.id) {
      // Edit
      const idx = products.findIndex(p => p.id === product.id);
      if (idx !== -1) {
        products[idx] = { ...products[idx], ...product };
      }
    } else {
      // Create
      product.id = "p_" + Date.now();
      products.push(product);
    }
    localStorage.setItem(DB_KEYS.PRODUCTS, JSON.stringify(products));
    this.addToSyncQueue("products", product);
    return product;
  },

  updateProductStock(productId, newQty) {
    const products = this.getProducts();
    const product = products.find(p => p.id === productId);
    if (product) {
      product.stockQty = Math.max(0, newQty);
      localStorage.setItem(DB_KEYS.PRODUCTS, JSON.stringify(products));
      this.addToSyncQueue("products", product);
    }
  },

  // --- Customers (Khata) ---
  getCustomers() {
    return JSON.parse(localStorage.getItem(DB_KEYS.CUSTOMERS)) || [];
  },

  saveCustomer(customer) {
    const customers = this.getCustomers();
    if (customer.id) {
      const idx = customers.findIndex(c => c.id === customer.id);
      if (idx !== -1) {
        customers[idx] = { ...customers[idx], ...customer };
      }
    } else {
      customer.id = "c_" + Date.now();
      customer.balance = 0;
      customers.push(customer);
    }
    localStorage.setItem(DB_KEYS.CUSTOMERS, JSON.stringify(customers));
    this.addToSyncQueue("customers", customer);
    return customer;
  },

  // --- Transactions (Khata Credit Ledger) ---
  getTransactions(customerId = null) {
    const txs = JSON.parse(localStorage.getItem(DB_KEYS.TRANSACTIONS)) || [];
    if (customerId) {
      return txs.filter(t => t.customerId === customerId).sort((a, b) => new Date(b.date) - new Date(a.date));
    }
    return txs.sort((a, b) => new Date(b.date) - new Date(a.date));
  },

  addTransaction(customerId, type, amount, description) {
    const tx = {
      id: "t_" + Date.now(),
      customerId,
      type, // 'credit' (customer owes store more) or 'payment' (customer paid store back)
      amount: parseFloat(amount),
      description,
      date: new Date().toISOString()
    };
    
    // Save transaction
    const txs = this.getTransactions();
    txs.push(tx);
    localStorage.setItem(DB_KEYS.TRANSACTIONS, JSON.stringify(txs));

    // Update Customer Balance
    const customers = this.getCustomers();
    const customer = customers.find(c => c.id === customerId);
    if (customer) {
      if (type === "credit") {
        customer.balance += tx.amount;
      } else {
        customer.balance -= tx.amount;
      }
      localStorage.setItem(DB_KEYS.CUSTOMERS, JSON.stringify(customers));
      this.addToSyncQueue("customers", customer);
    }

    this.addToSyncQueue("transactions", tx);
    return tx;
  },

  // --- Billing ---
  getBills() {
    const bills = JSON.parse(localStorage.getItem(DB_KEYS.BILLS)) || [];
    return bills.sort((a, b) => new Date(b.date) - new Date(a.date));
  },

  saveBill(bill) {
    bill.id = "b_" + Date.now();
    bill.date = new Date().toISOString();
    
    // Add bill
    const bills = this.getBills();
    bills.push(bill);
    localStorage.setItem(DB_KEYS.BILLS, JSON.stringify(bills));

    // Deduct stock for items
    const products = this.getProducts();
    bill.items.forEach(item => {
      const product = products.find(p => p.name === item.name);
      if (product) {
        product.stockQty = Math.max(0, product.stockQty - item.qty);
        this.addToSyncQueue("products", product);
      }
    });
    localStorage.setItem(DB_KEYS.PRODUCTS, JSON.stringify(products));

    // If payment method is Credit, record a transaction in Khata Ledger
    if (bill.paymentMethod === "credit" && bill.customerId) {
      this.addTransaction(
        bill.customerId,
        "credit",
        bill.total,
        `Credit bill no. ${bill.id.substring(0, 8)}`
      );
    }

    this.addToSyncQueue("bills", bill);
    return bill;
  },

  // --- Dashboard Analytics ---
  getMetrics() {
    const bills = this.getBills();
    const customers = this.getCustomers();
    const products = this.getProducts();

    // Today's Sales
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const todaySales = bills
      .filter(b => new Date(b.date) >= startOfToday)
      .reduce((sum, b) => sum + b.total, 0);

    // Total Credit Outstanding (positive customer balance indicates they owe)
    const totalCredit = customers
      .filter(c => c.balance > 0)
      .reduce((sum, c) => sum + c.balance, 0);

    // Low stock items
    const lowStockCount = products.filter(p => p.stockQty <= p.minThreshold).length;

    // Active customers
    const activeCustomers = customers.length;

    return {
      todaySales,
      totalCredit,
      lowStockCount,
      activeCustomers
    };
  },

  // --- Sync Simulation ---
  getSyncQueue() {
    return JSON.parse(localStorage.getItem(DB_KEYS.SYNC_QUEUE)) || [];
  },

  addToSyncQueue(collection, data) {
    const queue = this.getSyncQueue();
    queue.push({
      id: Date.now() + "_" + Math.random().toString(36).substr(2, 5),
      collection,
      data,
      timestamp: new Date().toISOString()
    });
    localStorage.setItem(DB_KEYS.SYNC_QUEUE, JSON.stringify(queue));
  },

  async processSyncQueue(onProgress) {
    const queue = this.getSyncQueue();
    if (queue.length === 0) return true;

    // Simulate async sync steps with a progress callback
    for (let i = 0; i < queue.length; i++) {
      if (onProgress) onProgress(i + 1, queue.length, queue[i]);
      await new Promise(resolve => setTimeout(resolve, 300)); // Simulating network latency
    }

    // Clear sync queue on completion
    localStorage.setItem(DB_KEYS.SYNC_QUEUE, JSON.stringify([]));
    return true;
  },

  // --- Loans (Sathi Rin / Shopkeeper P2P) ---
  getLoans() {
    return JSON.parse(localStorage.getItem(DB_KEYS.LOANS)) || [];
  },

  saveLoan(loan) {
    const loans = this.getLoans();
    if (loan.id) {
      const idx = loans.findIndex(l => l.id === loan.id);
      if (idx !== -1) loans[idx] = { ...loans[idx], ...loan };
    } else {
      loan.id = "l_" + Date.now();
      loan.repayments = [];
      loan.status = "active";
      loans.push(loan);
    }
    localStorage.setItem(DB_KEYS.LOANS, JSON.stringify(loans));
    this.addToSyncQueue("loans", loan);
    return loan;
  },

  addLoanRepayment(loanId, amount, note) {
    const loans = this.getLoans();
    const loan = loans.find(l => l.id === loanId);
    if (!loan) return null;

    const repayment = {
      id: "r_" + Date.now(),
      amount: parseFloat(amount),
      date: new Date().toISOString(),
      note: note || "Repayment"
    };
    loan.repayments.push(repayment);

    // Check if fully repaid
    const totalRepaid = loan.repayments.reduce((s, r) => s + r.amount, 0);
    const { totalDue } = this.getLoanCalculation(loan);
    if (totalRepaid >= totalDue) {
      loan.status = "repaid";
    }

    localStorage.setItem(DB_KEYS.LOANS, JSON.stringify(loans));
    this.addToSyncQueue("loans", loan);
    return repayment;
  },

  getLoanCalculation(loan) {
    const start = new Date(loan.startDate);
    const now = new Date();
    // Months elapsed (fractional)
    const monthsElapsed = (now - start) / (1000 * 60 * 60 * 24 * 30.44);
    // Simple interest: P * R * T / 100
    const interest = (loan.principalAmount * loan.interestRate * monthsElapsed) / (100 * 12);
    const totalDue = loan.principalAmount + interest;
    const totalRepaid = (loan.repayments || []).reduce((s, r) => s + r.amount, 0);
    const remaining = Math.max(0, totalDue - totalRepaid);
    return {
      interest: Math.round(interest),
      totalDue: Math.round(totalDue),
      totalRepaid: Math.round(totalRepaid),
      remaining: Math.round(remaining),
      monthsElapsed: parseFloat(monthsElapsed.toFixed(1))
    };
  },

  getLoanSummary() {
    const loans = this.getLoans();
    let totalLent = 0, totalBorrowed = 0;
    loans.forEach(loan => {
      if (loan.status === 'repaid') return;
      const { remaining } = this.getLoanCalculation(loan);
      if (loan.direction === 'lent') totalLent += remaining;
      else totalBorrowed += remaining;
    });
    return { totalLent, totalBorrowed, count: loans.length };
  },

  // Clean data reset for tests
  resetData() {
    localStorage.setItem(DB_KEYS.PRODUCTS, JSON.stringify(SEED_PRODUCTS));
    localStorage.setItem(DB_KEYS.CUSTOMERS, JSON.stringify(SEED_CUSTOMERS));
    localStorage.setItem(DB_KEYS.TRANSACTIONS, JSON.stringify(SEED_TRANSACTIONS));
    localStorage.setItem(DB_KEYS.BILLS, JSON.stringify(SEED_BILLS));
    localStorage.setItem(DB_KEYS.LOANS, JSON.stringify(SEED_LOANS));
    localStorage.setItem(DB_KEYS.SYNC_QUEUE, JSON.stringify([]));
  }
};
