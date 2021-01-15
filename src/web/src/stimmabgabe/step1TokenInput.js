import { Button, makeStyles } from "@material-ui/core";
import TextField from '@material-ui/core/TextField';

const useStyles = makeStyles(theme => ({
  button: {
    marginRight: theme.spacing(1),
  },
  instructions: {
    marginTop: theme.spacing(1),
    marginBottom: theme.spacing(1),
  },
}));


export default function Step1TokenInput(props) {
  const classes = useStyles()

  const handleNext = () => {
    props.setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };
  const handleBack = () => {
    props.setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  return <>
    <div>
      <form autoComplete="off">
        <TextField id="outlined-basic" label="Personalausweisnummer" variant="outlined" value={props.token} onChange={(event) => props.setToken(event.target.value)}/>
      </form>
    </div>
    <div>
      <Button disabled={props.activeStep === 0} onClick={handleBack} className={classes.button}>
        Zurück
              </Button>
      <Button
        variant="contained"
        color="primary"
        onClick={handleNext}
        className={classes.button}
      >
        Weiter
      </Button>
    </div>
  </>
}