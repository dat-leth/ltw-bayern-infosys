import React, { useEffect, useMemo, useState } from 'react';
import SideNavigation from "../src/SideNavigation";
import { makeStyles, Typography, Stepper, Step, StepLabel } from "@material-ui/core";
import { useRouter } from 'next/router';
import Step1TokenInput from "../src/stimmabgabe/step1TokenInput"
import Step2StimmzettelErststimme from '../src/stimmabgabe/step2StimmzettelErststimme';
import Step3StimmzettelZweitstimme from '../src/stimmabgabe/step3StimmzettelZweitstimme';
import Step4Confirm from '../src/stimmabgabe/step4Confirm';

const useStyles = makeStyles(theme => ({
  table: {
    width: '100%',
    padding: theme.spacing(7, 7)
  },
  wrapper: {
    display: 'flex',
    flexDirection: 'column',
    flex: '1 1 100%',
    padding: theme.spacing(5, 15, 0, 15),
    maxWidth: 1500
  },
  groupRow: {
    fontWeight: '500',
    backgroundColor: '#ecf2ff'
  },
  button: {
    marginRight: theme.spacing(1),
  },
  instructions: {
    marginTop: theme.spacing(1),
    marginBottom: theme.spacing(1),
  },
}));


export default function Stimmabgabe() {
  const router = useRouter();
  const { wahlkreis, stimmkreis, wahllokal } = router.query

  const classes = useStyles();

  const [activeStep, setActiveStep] = useState(0);
  const steps = ['Token zur Stimmabgabe eintragen', 'Erststimme abgeben', 'Zweitstimme abgeben', 'Stimmenabgabe bestätigen'];

  const [token, setToken] = useState('')
  const [stimmzettelErststimme, setStimmzettelErststimme] = useState()
  const [stimmzettelZweitstimme, setStimmzettelZweitstimme] = useState()
  const [erststimme, setErststimme] = useState(null)
  const [zweitstimme, setZweitstimme] = useState({
    kandidat: null,
    partei: null
  })

  useEffect(() => {
    if (stimmkreis) {
      fetch(`${process.env.NEXT_PUBLIC_BACKEND_URL}/rpc/stimmzettel_erststimme?stimmkreis=${stimmkreis}`).then(resp => {
        if (resp.ok) {
          resp.json()
            .then(data => { if (data) setStimmzettelErststimme(data) })
            .catch(err => console.error('Failed to deserialize JSON', err));
        } else {
          console.warn('Backend Request not successful', resp);
        }
      }).catch(err => console.error('Backend Request failed', err))
    }

    if (wahlkreis) {
      fetch(`${process.env.NEXT_PUBLIC_BACKEND_URL}/rpc/stimmzettel_zweitstimme?wahlkreis=${wahlkreis}`).then(resp => {
        if (resp.ok) {
          resp.json()
            .then(data => { if (data) setStimmzettelZweitstimme(data) })
            .catch(err => console.error('Failed to deserialize JSON', err));
        } else {
          console.warn('Backend Request not successful', resp);
        }
      }).catch(err => console.error('Backend Request failed', err))
    }
  }, [stimmkreis, wahlkreis]);

  useEffect(() => {
    if (activeStep === steps.length) {
      setTimeout(() => window.location.reload(), 5000)
    }
  }, [activeStep])

  return <>
    <SideNavigation drawerWidth={300} />
    <div className={classes.wrapper}>
      <Typography variant="h4" color="primary">Stimmabgabe in Wahlkreis {wahlkreis} / Stimmkreis {stimmkreis} / Wahllokal {wahllokal}</Typography>
      <Stepper activeStep={activeStep}>
        {steps.map((label) => {
          return (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          );
        })}
      </Stepper>
      <div>
        {activeStep === steps.length ? (
          <div>
            <Typography className={classes.instructions}>
              Vielen Dank für die Teilnahme an der Bayerischen Landtagswahl.
            </Typography>
          </div>
        ) : (
            <div>
              { activeStep === 0 && <Step1TokenInput maxSteps={steps.length} activeStep={activeStep} setActiveStep={setActiveStep} token={token} setToken={setToken}></Step1TokenInput>}
              { activeStep === 1 && <Step2StimmzettelErststimme maxSteps={steps.length} activeStep={activeStep} setActiveStep={setActiveStep} stimmzettelErststimme={stimmzettelErststimme} erststimme={erststimme} setErststimme={setErststimme}></Step2StimmzettelErststimme>}
              { activeStep === 2 && <Step3StimmzettelZweitstimme maxSteps={steps.length} activeStep={activeStep} setActiveStep={setActiveStep} stimmzettelZweitstimme={stimmzettelZweitstimme} zweitstimme={zweitstimme} setZweitstimme={setZweitstimme}></Step3StimmzettelZweitstimme>}
              { activeStep === 3 && <Step4Confirm wahlkreis={wahlkreis} stimmkreis={stimmkreis} wahllokal={wahllokal} maxSteps={steps.length} activeStep={activeStep} setActiveStep={setActiveStep} stimmzettelErststimme={stimmzettelErststimme} stimmzettelZweitstimme={stimmzettelZweitstimme} erststimme={erststimme} zweitstimme={zweitstimme} token={token}></Step4Confirm>}
            </div>
          )}
      </div>
    </div>
  </>
}