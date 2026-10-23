# Software model of the Task 3 self-test, used to find the reference signature
# Each function mirrors one hardware block


def bit(x, n):
    # Verilog x[n]
    return (x >> n) & 1


def prbs(n_words):
    # PRBS.sv: reset to 1, taps on bits 15, 13, 12, 10
    p = 1
    values = []
    for _ in range(n_words):
        values.append(p)                    # value on D when the write happens
        fb = bit(p, 15) ^ bit(p, 13) ^ bit(p, 12) ^ bit(p, 10)
        p = ((p << 1) | fb) & 0xFFFF        # {prbs[14:0], fb}
    return values


def fill_memory(stuck_at_0_bit=None):
    # SRAM: each address stores {prbs, prbs}
    mem = []
    for p in prbs(32):
        w = (p << 16) | p
        if stuck_at_0_bit is not None:
            w &= ~(1 << stuck_at_0_bit)     # inject a stuck-at-0 fault on one DATA bit
        mem.append(w)
    return mem


def xor_array(w):
    # xor_array.sv: upper half ^ lower half
    return (w >> 16) ^ (w & 0xFFFF)


def signature(mem):
    # signature_analyser.sv: cleared to 0, then one step per word read
    s = 0
    for w in mem:
        x = xor_array(w)
        fb = bit(s, 15) ^ bit(s, 4) ^ bit(s, 2) ^ bit(s, 1)
        s = (((s << 1) | fb) & 0xFFFF) ^ x  # {signature[14:0], fb} ^ data_in
    return s


if __name__ == "__main__":
    print(f"Good memory:      {signature(fill_memory()):04X}")
    for b in (0, 3, 16, 31):
        print(f"DATA[{b:2}] stuck-at-0: {signature(fill_memory(b)):04X}")
