# noinspection PyUnresolvedReferences
from array import array
cimport numpy as np
import numpy as np

from libcpp cimport bool

cpdef np.ndarray[np.uint8_t, ndim=3] build_xor_matrix(list bitvectors):
    cdef unsigned int maximum = 0
    cdef np.uint8_t[:] bitvector_i, bitvector_j
    cdef int i, j, l
    for i in range(0, len(bitvectors)):
        bitvector_i = bitvectors[i]
        if maximum < len(bitvector_i):
            maximum = len(bitvector_i)

    cdef np.ndarray[np.uint8_t, ndim=3] result = np.full((len(bitvectors), len(bitvectors), maximum), -1, dtype=np.uint8, order="C")

    for i in range(len(bitvectors)):
        bitvector_i = bitvectors[i]
        for j in range(i+1, len(bitvectors)):
            bitvector_j = bitvectors[j]
            l = min(len(bitvector_i), len(bitvector_j))
            for k in range(0, l):
                result[i,j,k] = bitvector_i[k] ^ bitvector_j[k]

    return result

cpdef set find_longest_common_sub_sequence_indices(np.uint8_t[::1] seq1, np.uint8_t[::1] seq2):
    cdef unsigned int i, j, longest = 0, counter = 0, len_bits1 = len(seq1), len_bits2 = len(seq2)
    cdef unsigned short max_results = 10, current_result = 0

    cdef unsigned int[:, ::1] m = np.zeros((len_bits1+1, len_bits2+1), dtype=np.uint32, order="C")
    cdef unsigned int[:, ::1] result_indices = np.zeros((max_results, 2), dtype=np.uint32, order="C")

    for i in range(0, len_bits1):
        for j in range(0, len_bits2):
            if seq1[i] == seq2[j]:
                counter = m[i, j] + 1
                m[i+1, j+1] = counter

                if counter > longest:
                    longest = counter

                    current_result = 0
                    result_indices[current_result, 0] = i - counter + 1
                    result_indices[current_result, 1] = i + 1
                elif counter == longest:
                    if current_result < max_results - 1:
                        current_result += 1
                        result_indices[current_result, 0] = i - counter + 1
                        result_indices[current_result, 1] = i + 1

    cdef set result = set()
    for i in range(current_result+1):
        result.add((result_indices[i, 0], result_indices[i, 1]))

    return result

cpdef int find_first_difference(unsigned char[:] bits1, unsigned char[:] bits2):
    cdef int i
    cdef int smaller_len = min(len(bits1), len(bits2))

    for i in range(smaller_len):
        if bits1[i] != bits2[i]:
            return i

    return smaller_len

cpdef list find_occurrences(np.uint8_t[::1] a, np.uint8_t[::1] b,
                            unsigned long[:] ignore_indices=None, return_after_first=False):
    """
    Find the indices of occurrences of b in a. 
    
    :param a: Larger array
    :param b: Subarray to search for
    :return: List of start indices of b in a 
    """
    cdef unsigned long i, j
    cdef unsigned long len_a = len(a), len_b = len(b)

    if ignore_indices is None:
        ignore_indices = array("L", [])

    if len_b > len_a:
        return []

    cdef list result = []
    cdef bool found
    for i in range(0, (len_a-len_b) + 1):
        found = True
        for j in range(0, len_b):
            if a[i+j] != b[j] or i+j in ignore_indices:
                found = False
                break
        if found:
            if return_after_first:
                return [i]
            else:
                result.append(i)

    return result
