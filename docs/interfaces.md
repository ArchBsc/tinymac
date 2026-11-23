## 1. Σκοπός

Το παρόν έγγραφο ορίζει τα **interfaces και τη συμπεριφορά των modules** που αποτελούν τον TinyMAC Accelerator.

Στόχος είναι οι τρεις υποομάδες να μπορούν να αναπτύσσουν και να ελέγχουν ανεξάρτητα τα modules τους, γνωρίζοντας ακριβώς πώς θα επικοινωνούν μεταξύ τους.

### 1.1 Γενική λειτουργία

Ο TinyMAC είναι ένας ψηφιακός επιταχυντής που εκτελεί πράξεις **Multiply–Accumulate (MAC)**:

$$
ACC_{new} = ACC_{old} + (X \times W)
$$

Όπου:

- **X:** Αριθμός εισόδου (signed 4-bit).

- **W:** Βάρος πολλαπλασιασμού (signed 4-bit).

- **ACC:** Καταχωρητής 16-bit που αποθηκεύει το συνολικό άθροισμα.

- **Bias:** Αρχική τιμή (signed 8-bit) που μπορούμε να φορτώσουμε στον ACC.


Το κύκλωμα θα υποστηρίζει τρεις βασικές λειτουργίες:

1. **IDLE:** Διατήρηση της προηγούμενης τιμής του ACC.

2. **LOAD_BIAS:** Αντικατάσταση της τιμής του ACC με το bias.

3. **MAC:** Πολλαπλασιασμός X × W και πρόσθεση στον ACC.


Σε περίπτωση υπερχείλισης του accumulator θα χρησιμοποιείται **saturation**, ώστε η τιμή να περιορίζεται στο εύρος του signed 16-bit.

Οι τιμές X, W και Bias θα δίνονται εξωτερικά. Το κύκλωμα δεν εκτελεί εκπαίδευση AI μοντέλων.

## 2. Αρχιτεκτονική του συστήματος

Ο TinyMAC θα αποτελείται από τέσσερα βασικά SystemVerilog modules.

### 2.1 Modules και αρμοδιότητες

|Module|Περιγραφή|
|---|---|
|`mac_datapath.sv`|Εκτελεί τον πολλαπλασιασμό, την πρόσθεση και αποθηκεύει το αποτέλεσμα στον accumulator. Υποστηρίζει επίσης φόρτωση bias και saturation.|
|`mac_controller.sv`|Διαχειρίζεται την FSM, αναγνωρίζει τις εντολές και παράγει τα control signals για τον Datapath.|
|`mac_core.sv`|Συνδέει τον Controller με τον Datapath και αποτελεί το κεντρικό module του MAC Accelerator.|
|`project.v`|Συνδέει το `mac_core` με τα εξωτερικά pins του Tiny Tapeout.|

### 2.2 Επικοινωνία μεταξύ modules

**`mac_controller`** **→** **`mac_datapath`**

Ο Controller στέλνει τα control signals `acc_we`, `mac_en` και `load_bias`, καθορίζοντας ποια λειτουργία θα εκτελέσει ο Datapath.

**`mac_datapath`** **→** **`mac_core`**

Ο Datapath επιστρέφει το αποτέλεσμα του accumulator (`acc`).

**`mac_core`** **→** **`project.v`**

Το `mac_core` δέχεται τις εξωτερικές εντολές και τα δεδομένα μέσω του `project.v` και επιστρέφει το αποτέλεσμα.

### 2.3 Verification

Κάθε υποομάδα θα αναπτύσσει ξεχωριστό testbench για το module της.

- `tb_datapath.sv`: Έλεγχος αριθμητικών πράξεων και accumulator.

- `tb_controller.sv`: Έλεγχος FSM, εντολών και control signals.

- `test.py` / `tb.v`: Έλεγχος της συνολικής λειτουργίας μέσω του Tiny Tapeout interface.


Τα testbenches χρησιμοποιούνται μόνο στην προσομοίωση και **δεν αποτελούν μέρος του τελικού ASIC**.

### 2.4 Interface — `mac_datapath.sv`

**Υπεύθυνη:** Υποομάδα 1 — MAC Datapath

#### 2.4.1 Inputs / Outputs

|Signal|Direction|Type|Περιγραφή|
|---|---|---|---|
|`clk`|Input|`logic`|Clock του συστήματος|
|`rst_n`|Input|`logic`|Active-low reset|
|`x`|Input|`logic signed [3:0]`|Αριθμός εισόδου|
|`w`|Input|`logic signed [3:0]`|Βάρος πολλαπλασιασμού|
|`bias`|Input|`logic signed [7:0]`|Αρχική τιμή του accumulator|
|`acc_we`|Input|`logic`|Επιτρέπει εγγραφή στον accumulator|
|`mac_en`|Input|`logic`|Επιλέγει τη λειτουργία MAC|
|`load_bias`|Input|`logic`|Επιλέγει τη φόρτωση bias|
|`acc`|Output|`logic signed [15:0]`|Αποθηκευμένη τιμή του accumulator|

#### 2.4.2 Λειτουργία των Control Signals

|`acc_we`|`mac_en`|`load_bias`|Ενέργεια|
|---|---|---|---|
|0|X|X|Διατήρηση του ACC|
|1|1|0|`ACC ← ACC + (x × w)`|
|1|0|1|`ACC ← bias`|
|1|0|0|Μη έγκυρος συνδυασμός|
|1|1|1|Μη έγκυρος συνδυασμός|

_X = Don't Care (η τιμή δεν επηρεάζει τη συγκεκριμένη λειτουργία)._

Για τους μη έγκυρους συνδυασμούς, ο accumulator δεν πρέπει να ενημερώνεται.

#### 2.4.3 Clock και Reset

- Η ενημέρωση του ACC γίνεται στο **rising edge** του `clk`.

- Όταν `acc_we = 0`, ο ACC διατηρεί την προηγούμενη τιμή του.

- Όταν `rst_n = 0`, ο ACC μηδενίζεται ανεξάρτητα από το clock (asynchronous reset).

- Το `acc` επιστρέφει συνεχώς την τελευταία αποθηκευμένη τιμή.


#### 2.4.4 Arithmetic Rules

- Τα `x` και `w` είναι signed 4-bit αριθμοί.

- Το γινόμενό τους υπολογίζεται σε signed 8-bit.

- Ο accumulator είναι signed 16-bit.

- Το `bias` επεκτείνεται με διατήρηση προσήμου (sign extension) στα 16-bit.

- Σε overflow εφαρμόζεται **saturation**:

    - Maximum: `32767`

    - Minimum: `-32768`


Η εσωτερική υλοποίηση αποτελεί ευθύνη της υποομάδας, αρκεί να τηρεί αυτή την προδιαγραφή.

### 2.5 Interface — `mac_controller.sv`

**Υπεύθυνη:** Υποομάδα 2 — MAC Controller

#### 2.5.1 Inputs / Outputs

|Signal|Direction|Type|Περιγραφή|
|---|---|---|---|
|`clk`|Input|`logic`|Clock του συστήματος|
|`rst_n`|Input|`logic`|Active-low reset|
|`opcode`|Input|`logic [1:0]`|Κωδικός εντολής|
|`strobe`|Input|`logic`|Σήμα εκτέλεσης νέας εντολής|
|`acc_we`|Output|`logic`|Επιτρέπει εγγραφή στον ACC|
|`mac_en`|Output|`logic`|Επιλέγει τη λειτουργία MAC|
|`load_bias`|Output|`logic`|Επιλέγει τη φόρτωση bias|

#### 2.5.2 Εντολές (Opcodes)

|Opcode|Εντολή|Λειτουργία|
|---|---|---|
|`00`|IDLE|Καμία αλλαγή στον ACC|
|`01`|LOAD_BIAS|Φόρτωση bias στον ACC|
|`10`|MAC|Εκτέλεση πράξης MAC|
|`11`|RESERVED|Δεν εκτελείται καμία πράξη|

#### 2.5.3 Καταστάσεις της FSM

Η FSM θα αποτελείται από δύο καταστάσεις:

- **READY:** Ο Controller μπορεί να δεχτεί νέα εντολή.

- **WAIT_RELEASE:** Έχει δεχτεί εντολή και περιμένει το `strobe` να επιστρέψει στο 0.


**State Transitions:**

|Current State|Strobe|Next State|
|---|---|---|
|READY|0|READY|
|READY|1|WAIT_RELEASE|
|WAIT_RELEASE|0|READY|
|WAIT_RELEASE|1|WAIT_RELEASE|

Οι μεταβάσεις πραγματοποιούνται στο rising edge του `clk`.

#### 2.5.4 Control Signals

Ο Controller επιτρέπεται να ενεργοποιήσει τα control signals μόνο όταν:

`state == READY && strobe == 1 && rst_n == 1`

|Opcode|`acc_we`|`mac_en`|`load_bias`|
|---|---|---|---|
|IDLE|0|0|0|
|LOAD_BIAS|1|0|1|
|MAC|1|1|0|
|RESERVED|0|0|0|

Όταν η FSM βρίσκεται στο `WAIT_RELEASE`, όλα τα control signals παραμένουν 0.

#### 2.5.5 Clock, Reset και Strobe

- Η FSM ενημερώνει το state στο **rising edge** του `clk`.

- Όταν `rst_n = 0`, επιστρέφει ασύγχρονα στο `READY`.

- Όσο το reset είναι ενεργό, όλα τα control signals παραμένουν 0.

- Κάθε νέα εντολή εκτελείται **μόνο μία φορά**.

- Το `strobe` πρέπει να γίνει 0 και να δειγματοληφθεί σε ένα rising edge πριν γίνει αποδεκτή νέα εντολή.

- Το `opcode` και τα δεδομένα πρέπει να είναι σταθερά πριν και κατά την ενεργή ακμή εκτέλεσης, τηρώντας τους χρόνους setup/hold.


Η εσωτερική υλοποίηση της FSM αποτελεί ευθύνη της υποομάδας, αρκεί να τηρεί την παραπάνω συμπεριφορά.

### 2.6 Interface — `mac_core.sv`

**Υπεύθυνη:** Υποομάδα 3 — Integration & Physical Design

#### 2.6.1 Σκοπός

Το `mac_core` είναι το κεντρικό module του MAC Accelerator.

Δημιουργεί instances των `mac_controller` και `mac_datapath` και συνδέει τα μεταξύ τους σήματα.

Χρησιμοποιεί τα δύο υπάρχοντα modules.

#### 2.6.2 Inputs / Outputs

|Signal|Direction|Type|Περιγραφή|
|---|---|---|---|
|`clk`|Input|`logic`|Clock του συστήματος|
|`rst_n`|Input|`logic`|Active-low reset|
|`opcode`|Input|`logic [1:0]`|Εντολή προς τον Controller|
|`strobe`|Input|`logic`|Σήμα νέας εντολής|
|`x`|Input|`logic signed [3:0]`|Αριθμός εισόδου|
|`w`|Input|`logic signed [3:0]`|Βάρος πολλαπλασιασμού|
|`bias`|Input|`logic signed [7:0]`|Αρχική τιμή accumulator|
|`acc`|Output|`logic signed [15:0]`|Αποτέλεσμα accumulator|

#### 2.6.3 Εσωτερικά σήματα

Το `mac_core` θα χρησιμοποιεί τρία εσωτερικά σήματα για την επικοινωνία Controller–Datapath.

|Signal|Source|Destination|
|---|---|---|
|`acc_we`|Controller|Datapath|
|`mac_en`|Controller|Datapath|
|`load_bias`|Controller|Datapath|

Τα σήματα αυτά δεν αποτελούν εξωτερικά ports του `mac_core`.

#### 2.6.4 Λειτουργία

1. Το `mac_core` λαμβάνει τα `opcode` και `strobe` και τα μεταφέρει στον Controller.

2. Ο Controller παράγει τα κατάλληλα control signals.

3. Τα control signals μεταφέρονται στον Datapath.

4. Ο Datapath εκτελεί την επιλεγμένη λειτουργία και ενημερώνει τον ACC στο κατάλληλο rising edge.

5. Η αποθηκευμένη τιμή του ACC επιστρέφεται μέσω του output `acc`.


Το `clk` και το `rst_n` συνδέονται και στα δύο modules.

Το `mac_core` δεν προσθέτει επιπλέον κύκλους καθυστέρησης (latency) και δεν περιέχει δική του FSM ή accumulator.

#### 2.6.5 Verification

Η υποομάδα θα πραγματοποιήσει integration tests για να επιβεβαιώσει ότι τα δύο modules συνεργάζονται σωστά.

**Βασικά tests:**

- `LOAD_BIAS` και έλεγχος αρχικής τιμής ACC.

- Μία ή περισσότερες διαδοχικές εντολές `MAC`.

- `IDLE` χωρίς αλλαγή του ACC.

- Παρατεταμένο `strobe = 1` χωρίς επανάληψη πράξης.

- Reset κατά τη διάρκεια λειτουργίας.

- Έλεγχος θετικών και αρνητικών αποτελεσμάτων.


**Παραδοτέο:** Λειτουργικό `mac_core.sv` που συνδέει Controller και Datapath και περνά τα integration tests.

### 2.7 Interface — `project.v`

**Υπεύθυνη:** Υποομάδα 3 — Integration & Physical Design

#### 2.7.1 Σκοπός

Το `project.v` είναι το top-level module του Tiny Tapeout.

Συνδέει το `mac_core` με τα εξωτερικά pins του chip και μετατρέπει τα δεδομένα εισόδου στην κατάλληλη μορφή.

#### 2.7.2 Tiny Tapeout Interface

|Signal|Direction|Width|Περιγραφή|
|---|---|---|---|
|`ui_in`|Input|8-bit|Dedicated inputs|
|`uo_out`|Output|8-bit|Dedicated outputs|
|`uio_in`|Input|8-bit|Bidirectional pins — input path|
|`uio_out`|Output|8-bit|Bidirectional pins — output path|
|`uio_oe`|Output|8-bit|Output enable για τα bidirectional pins|
|`clk`|Input|1-bit|Clock|
|`rst_n`|Input|1-bit|Active-low reset|
|`ena`|Input|1-bit|Tiny Tapeout design enable|

Το `ena` δεν θα χρησιμοποιείται από τη δική μας λογική στην αρχική έκδοση.

#### 2.7.3 Input Pin Mapping

**Dedicated inputs —** **`ui_in[7:0]`**

|Pins|Signal|Περιγραφή|
|---|---|---|
|`ui_in[7:6]`|`opcode`|Επιλογή εντολής|
|`ui_in[5:3]`|Reserved|Δεσμευμένα για μελλοντική χρήση|
|`ui_in[2:1]`|`read_sel`|Επιλογή byte αποτελέσματος|
|`ui_in[0]`|`strobe`|Δήλωση νέας εντολής|

**Bidirectional inputs —** **`uio_in[7:0]`**

|Εντολή|Pins|Δεδομένα|
|---|---|---|
|MAC|`uio_in[7:4]`|Signed 4-bit `w`|
|MAC|`uio_in[3:0]`|Signed 4-bit `x`|
|LOAD_BIAS|`uio_in[7:0]`|Signed 8-bit `bias`|

Τα ίδια pins χρησιμοποιούνται για διαφορετικά δεδομένα, ανάλογα με την εντολή (_input multiplexing_).

#### 2.7.4 Output Pin Mapping

Το `mac_core` παράγει ένα signed 16-bit αποτέλεσμα (`acc`).

Επειδή το `uo_out` διαθέτει 8 bits, το αποτέλεσμα διαβάζεται σε δύο τμήματα.

|`read_sel`|`uo_out[7:0]`|
|---|---|
|`00`|`acc[7:0]` — Lower byte|
|`01`|`acc[15:8]` — Upper byte|
|`10`|`8'b00000000`|
|`11`|`8'b00000000`|

Η επιλογή γίνεται με συνδυαστική λογική, χωρίς να αλλάζει η αποθηκευμένη τιμή του ACC.

Τα bidirectional pins θα χρησιμοποιούνται μόνο ως inputs:

- `uio_out = 8'b00000000`

- `uio_oe = 8'b00000000`


#### 2.7.5 Λειτουργία

1. Το `project.v` λαμβάνει την εντολή μέσω του `opcode`.

2. Μεταφέρει τα `x`, `w`, `bias`, `opcode` και `strobe` στο `mac_core`.

3. Το `mac_core` εκτελεί την επιλεγμένη λειτουργία στο κατάλληλο rising edge.

4. Το `project.v` επιλέγει το κατάλληλο byte του αποτελέσματος μέσω του `read_sel`.

5. Το επιλεγμένο byte εμφανίζεται στο `uo_out`.


Η ανάγνωση του αποτελέσματος δεν απαιτεί ξεχωριστή εντολή ούτε ενεργοποίηση του `strobe`.

#### 2.7.6 Verification

**Βασικά tests:**

- Σωστή αντιστοίχιση των input pins.

- Εκτέλεση `LOAD_BIAS` και `MAC` μέσω του εξωτερικού interface.

- Ανάγνωση Lower και Upper byte.

- Σωστή ανακατασκευή του 16-bit αποτελέσματος.

- Έλεγχος `rst_n` και `strobe`.

- Επιβεβαίωση ότι `uio_oe = 0` και `uio_out = 0`.


**Παραδοτέο:** Λειτουργικό `project.v` που συνδέει το TinyMAC με το Tiny Tapeout interface και περνά τα integration tests.

## 3. Verification — Έλεγχος λειτουργίας

### 3.1 Στόχος

Κάθε module πρέπει να ελέγχεται ανεξάρτητα πριν συνδεθεί με τα υπόλοιπα.

Το verification χωρίζεται σε δύο επίπεδα:

- **Unit Testing:** Έλεγχος κάθε module ξεχωριστά.

- **Integration Testing:** Έλεγχος της συνολικής λειτουργίας του TinyMAC.


### 3.2 Unit Tests — Υποομάδες 1 & 2

**Υποομάδα 1 —** **`tb_datapath.sv`**

Πρέπει να ελέγχει:

- Πολλαπλασιασμό θετικών και αρνητικών αριθμών.

- Σωστή εκτέλεση `ACC + X × W`.

- Φόρτωση θετικού και αρνητικού bias.

- Διατήρηση ACC όταν `acc_we = 0`.

- Reset και μη έγκυρους συνδυασμούς control signals.

- Saturation σε θετικό και αρνητικό overflow.


**Υποομάδα 2 —** **`tb_controller.sv`**

Πρέπει να ελέγχει:

- Σωστές μεταβάσεις `READY ↔ WAIT_RELEASE`.

- Σωστή αποκωδικοποίηση των τεσσάρων opcodes.

- Σωστή παραγωγή `acc_we`, `mac_en`, `load_bias`.

- Μία μόνο εκτέλεση όταν `strobe = 1` για πολλούς κύκλους.

- Επαναφορά στο READY μετά το reset.


### 3.3 Integration Tests — Υποομάδα 3

**Αρχεία:** `test.py`, `tb.v`

Η υποομάδα θα ελέγχει το ολοκληρωμένο κύκλωμα μέσω των εξωτερικών pins του `project.v`.

Βασικά test cases:

|Test|Εντολές|Αναμενόμενο ACC|
|---|---|---|
|1|Reset|`0`|
|2|`LOAD_BIAS(10)`|`10`|
|3|`MAC(3, -2)`|`4`|
|4|`MAC(-8, -8)`|`68`|
|5|`IDLE`|`68`|

Οι εντολές του πίνακα εκτελούνται με τη σειρά τους, με σωστή ακολουθία `strobe`.

Επιπλέον πρέπει να ελέγχονται:

- Ανάγνωση Lower και Upper byte μέσω `read_sel`.

- Σωστή ανακατασκευή signed 16-bit αποτελέσματος.

- Reset κατά τη λειτουργία.

- Παρατεταμένο `strobe = 1` χωρίς επανάληψη πράξης.

- Saturation στα όρια του accumulator.


### 3.4 Κριτήρια ολοκλήρωσης

Ένα module θεωρείται έτοιμο για integration όταν:

1. Ακολουθεί το συμφωνημένο interface.

2. Περνά όλα τα προβλεπόμενα tests.

3. Δεν εμφανίζει απρόσμενες τιμές (`X`) στις ελεγχόμενες εξόδους μετά το reset.

4. Έχει ελεγχθεί από τουλάχιστον ένα ακόμη μέλος μέσω Pull Request.


Το τελικό TinyMAC θεωρείται λειτουργικά επαληθευμένο όταν περνά επιτυχώς όλα τα unit και integration tests.

**Σημείωση:** Τα testbenches χρησιμοποιούνται μόνο στην προσομοίωση και δεν αποτελούν μέρος του τελικού ASIC.
