import { createMuiTheme } from '@material-ui/core/styles';
import { red } from '@material-ui/core/colors';

// Create a theme instance.
const theme = createMuiTheme({
    palette: {
        primary: {
            main: '#039be5'
        },
        secondary: {
            main: '#b000a7',
        },
        text: {
            primary: '#222',
            secondary: '#333'
        }
    },
    typography: {
        fontWeightRegular: 200,
        fontWeightBold: 300,

        h4: {
            fontWeight: 300
        },
        subtitle1: {
            fontSize: '13pt'
        }
    }
});

export default theme;
