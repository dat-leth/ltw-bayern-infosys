const COLORS = {
    'CSU': '#0080c8',
    'SPD': '#E3000F',
    'AFD': '#3399CC',
    'GRÜNE': '#64a12d',
    'FREIE WÄHLER': '#007E84',
    'FDP': '#ffed00'
};

export const getPartyColor = party => (COLORS[party.toLocaleUpperCase()] || '#ddd');

export class PARTEI_COLOR {
}
