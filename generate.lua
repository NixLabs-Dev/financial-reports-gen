local config = require("config")
local blesta = require("blestalib")
local currentTimeTable = os.date("!*t")
local previousMonthTable = {}

previousMonthTable.min = 0
previousMonthTable.hour = 0
previousMonthTable.day = 1
previousMonthTable.month = currentTimeTable.month - 1
previousMonthTable.year = currentTimeTable.year

local previousMonthEpoch = os.time(previousMonthTable)
-- This is the start of the previous month

print("Previous month epoch: " .. previousMonthEpoch)

local function replaceInString(input,placeholder,replacement)
  return input:gsub(placeholder,replacement)
end

local currentMonthTable = {}
currentMonthTable.min = 0
currentMonthTable.hour = 0
currentMonthTable.day = 1
currentMonthTable.month = currentTimeTable.month
currentMonthTable.year = currentTimeTable.year

local currentMonthEpoch = os.time(currentMonthTable)

print("Current month epoch: " .. currentMonthEpoch)

local transactionsUnfiltered = blesta.transactions.getList()
local transactions = {}

for i,o in pairs(transactionsUnfiltered) do
    --print(o.date_added)
    -- 2024-10-15 14:36:31
    -- Adapted from: https://stackoverflow.com/questions/4105012/convert-a-string-date-to-a-timestamp
    local year,month,day,hour,min,sec = o.date_added:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    local offset = os.epoch("utc") / 1000 - os.time(os.date("!*t"))
    -- These two are UNIX epochs in seconds
    --print(offset)
    local transactionEpoch = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec}) + offset
    if transactionEpoch > previousMonthEpoch and transactionEpoch < currentMonthEpoch then
        table.insert(transactions,o)
        print(textutils.serialise(o))
    end
end

print(#transactions .. " total transactions")

local totalTransactionAmount = 0
local approvedTransactions = 0

for i,o in pairs(transactions) do
    if o.status == "approved" then
        approvedTransactions = approvedTransactions + 1
        totalTransactionAmount = totalTransactionAmount + o.applied_amount
    end
    
end

print(totalTransactionAmount .. " USD of revenue")
print(approvedTransactions .. " transactions approved")

print("Entering Bill entry mode")
local done = false
local bills = settings.get("bills",{})
while not done do
  term.clear()
  term.setCursorPos(1,1)
  print("What do you want to do?")
  print("1) Enter a bill type and amount")
  print("2) List the current bill types and amounts in the system")
  print("3) Edit a bill type and amount")
  print("4) Clear the bills")
  print("5) Continue")
  term.write("> ")
  local input = read()
  if input == "1" then
    term.write("Enter the bill type: ")
    local billType = read()
    print("")
    term.write("Enter the amount: ")
    local billAmount = tonumber(read())
    if billAmount then
        bills[billType] = billAmount
        print("Your changes have been saved")
    else
        print("Bill amount " .. billAmount .. " was unreadable, your changes have not been saved")
    end
  elseif input == "2" then
    for billType,billAmount in pairs(bills) do
        print(billType .. ": " .. billAmount .. "$")
    end
  elseif input == "3" then
    for billType,billAmount in pairs(bills) do
      print(billType .. ": " .. billAmount .. "$")
    end
    print("")
    print("Enter the bill type you want to edit: ")
    local billType = read()
    if bills[billType] then
        print("Enter the amount you want to set: ")
        local billAmount = tonumber(read())
        if billAmount then
          bills[billType] = billAmount
          print("Your changes have been saved")
        else
          print("Bill amount " .. billAmount .. " was unreadable, your changes have not been saved")
        end
    else
      print("That bill type couldn't be found")
    end
  elseif input == "4" then
    bills = {}
    print("Your bills have been cleared")
  elseif input == "5" then
    done = true
  end

  print("Press enter to continue")
  read()
  settings.set("bills",bills)
  settings.save()
end

local expenses = 0
local bills_graph_values = "["
local bills_graph_labels = "["
for billType,billAmount in pairs(bills) do
  expenses = expenses + billAmount
  bills_graph_values = bills_graph_values .. billAmount .. ", "
  bills_graph_labels = bills_graph_labels .. "\'" .. billType .. "\', "
end

local bills_graph_values = bills_graph_values .. "]"
local bills_graph_labels = bills_graph_labels .. "]"

local balance = totalTransactionAmount - expenses

local h = fs.open("template.html","r")
local html = h.readAll()
h.close()

html = html:gsub("COMPANY_PLACEHOLDER",config.company_name)
html = html:gsub("DATE_PLACEHOLDER",os.date("%B %Y",previousMonthEpoch))
html = html:gsub("REVENUE_PLACEHOLDER",totalTransactionAmount)
html = html:gsub("EXPENSES_PLACEHOLDER",expenses)
html = html:gsub("BALANCE_PLACEHOLDER",balance)
html = html:gsub("BILLS_GRAPH_DATA_PLACEHOLDER",bills_graph_values)
html = html:gsub("BILLS_GRAPH_LABELS_PLACEHOLDER",bills_graph_labels)


local h = fs.open("output.html","w")
h.write(html)
h.close()

print("Should be all doneso!! :3")