/**
 * Groups the entries in @array by the value returned by @selector.
 * @param array the elements to group.
 * @param selector a selector for the value to group by.
 * @example groupBy([{a: 1, b: 2},{a: 1, b: 3},{a: 2, b: 4}], o => o.a) => {a: [{a: 1, b: 2},{a: 1, b: 3}],b:[{a: 2, b: 4}]}
 */
export const groupBy = (array, selector) => array.reduce((p, c) => ({
    ...p, // copy complete result
    [selector(c)]: [
        ...(p[selector(c)] || []), // copy existing array (already group elements)
        c // add new row
    ]
}), {});
