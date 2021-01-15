import { Button, makeStyles } from "@material-ui/core";


const useStyles = makeStyles(theme => ({
  button: {
    marginRight: theme.spacing(1),
  },
  instructions: {
    marginTop: theme.spacing(1),
    marginBottom: theme.spacing(1),
  },
}));


export default function Step4Confirm(props) {
  const classes = useStyles()

  const handleNext = () => {
    props.setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };
  const handleBack = () => {
    // TODO: Perform POST
    props.setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const getErststimme = () => {
    const kandidat = props.stimmzettelErststimme?.find((kandidat) => kandidat.nummer === props.erststimme);

    if (kandidat) {
      return `${kandidat.name} (${kandidat.partei})`
    } else {
      return 'Enthaltung'
    }
  }

  const getZweitstimme = () => {
    const kandidat = props.stimmzettelZweitstimme?.find((kandidat) => kandidat.persnr === props.zweitstimme.kandidat);
    if (kandidat && !props.zweitstimme.partei) {
      return `${kandidat.name} (${kandidat.partei})`
    } else if (!kandidat && props.zweitstimme.partei) {
      return `Liste der ${props.zweitstimme.partei} angenommen`
    } else {
      return 'Enthaltung'
    }
  }

  return <>
    <div>
      <dl>
        <dd>Ihre Personalausweisnummer</dd>
        <dt>{props.token}</dt>
        <dd>Ihre Erststimme</dd>
        <dt>{getErststimme()}</dt>
        <dd>Ihre Zweitstimme</dd>
        <dt>{getZweitstimme()}</dt>
      </dl>
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
        Absenden
      </Button>
    </div>
  </>
}